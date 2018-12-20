defmodule Mobilizon.Service.ActivityPub.Transmogrifier do
  @moduledoc """
  A module to handle coding from internal to wire ActivityPub and back.
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Comment}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils

  require Logger

  def get_actor(%{"actor" => actor}) when is_binary(actor) do
    actor
  end

  def get_actor(%{"actor" => actor}) when is_list(actor) do
    if is_binary(Enum.at(actor, 0)) do
      Enum.at(actor, 0)
    else
      Enum.find(actor, fn %{"type" => type} -> type in ["Person", "Service", "Application"] end)
      |> Map.get("id")
    end
  end

  def get_actor(%{"actor" => %{"id" => id}}) when is_bitstring(id) do
    id
  end

  def get_actor(%{"actor" => nil, "attributedTo" => actor}) when not is_nil(actor) do
    get_actor(%{"actor" => actor})
  end

  @doc """
  Modifies an incoming AP object (mastodon format) to our internal format.
  """
  def fix_object(object) do
    object
    |> Map.put("actor", object["attributedTo"])
    |> fix_attachments
    |> fix_in_reply_to
    |> fix_tag
  end

  def fix_in_reply_to(%{"inReplyTo" => in_reply_to} = object)
      when not is_nil(in_reply_to) do
    in_reply_to_id =
      cond do
        # If the inReplyTo is just an AP ID
        is_bitstring(in_reply_to) ->
          in_reply_to

        # If the inReplyTo is a object itself
        is_map(in_reply_to) && is_bitstring(in_reply_to["id"]) ->
          in_reply_to["id"]

        # If the inReplyTo is an array
        is_list(in_reply_to) && is_bitstring(Enum.at(in_reply_to, 0)) ->
          Enum.at(in_reply_to, 0)

        true ->
          Logger.error("inReplyTo ID seem incorrect")
          Logger.error(inspect(in_reply_to))
          ""
      end

    case fetch_obj_helper(in_reply_to_id) do
      {:ok, replied_object} ->
        object
        |> Map.put("inReplyTo", replied_object.url)

      {:error, {:error, :not_supported}} ->
        Logger.info("Object reply origin has not a supported type")
        object

      e ->
        Logger.error("Couldn't fetch #{in_reply_to_id} #{inspect(e)}")
        object
    end
  end

  def fix_in_reply_to(object), do: object

  def fix_attachments(object) do
    attachments =
      (object["attachment"] || [])
      |> Enum.map(fn data ->
        url = [%{"type" => "Link", "mediaType" => data["mediaType"], "href" => data["url"]}]
        Map.put(data, "url", url)
      end)

    object
    |> Map.put("attachment", attachments)
  end

  def fix_tag(object) do
    tags =
      (object["tag"] || [])
      |> Enum.filter(fn data -> data["type"] == "Hashtag" and data["name"] end)
      |> Enum.map(fn data -> String.slice(data["name"], 1..-1) end)

    combined = (object["tag"] || []) ++ tags

    object
    |> Map.put("tag", combined)
  end

  # TODO: validate those with a Ecto scheme
  # - tags
  # - emoji
  def handle_incoming(%{"type" => "Create", "object" => %{"type" => "Note"} = object} = data) do
    Logger.info("Handle incoming to create notes")

    with {:ok, %Actor{} = actor} <- Actors.get_or_fetch_by_url(data["actor"]) do
      Logger.debug("found actor")
      Logger.debug(inspect(actor))

      params = %{
        to: data["to"],
        object: object |> fix_object,
        actor: actor,
        local: false,
        published: data["published"],
        additional:
          Map.take(data, [
            "cc",
            "id"
          ])
      }

      ActivityPub.create(params)
    end
  end

  def handle_incoming(
        %{"type" => "Follow", "object" => followed, "actor" => follower, "id" => id} = data
      ) do
    with {:ok, %Actor{} = followed} <- Actors.get_or_fetch_by_url(followed, true),
         {:ok, %Actor{} = follower} <- Actors.get_or_fetch_by_url(follower),
         {:ok, activity} <- ActivityPub.follow(follower, followed, id, false) do
      ActivityPub.accept(%{to: [follower.url], actor: followed.url, object: data, local: true})

      {:ok, activity}
    else
      e ->
        Logger.error("Unable to handle Follow activity")
        Logger.error(inspect(e))
        :error
    end
  end

  #
  #  def handle_incoming(
  #        %{"type" => "Like", "object" => object_id, "actor" => actor, "id" => id} = data
  #      ) do
  #    with %User{} = actor <- User.get_or_fetch_by_ap_id(actor),
  #         {:ok, object} <-
  #           fetch_obj_helper(object_id) || ActivityPub.fetch_object_from_id(object_id),
  #         {:ok, activity, object} <- ActivityPub.like(actor, object, id, false) do
  #      {:ok, activity}
  #    else
  #      _e -> :error
  #    end
  #  end
  # #
  # def handle_incoming(
  #       %{"type" => "Announce", "object" => object_id, "actor" => actor, "id" => id} = data
  #     ) do
  #   with actor <- get_actor(data),
  #        {:ok, %Actor{} = actor} <- Actors.get_or_fetch_by_url(actor),
  #        {:ok, object} <- get_obj_helper(object_id) || fetch_obj_helper(object_id),
  #        {:ok, activity, _object} <- ActivityPub.announce(actor, object, id, false) do
  #     {:ok, activity}
  #   else
  #     e -> Logger.error(inspect e)
  #       :error
  #   end
  # end

  def handle_incoming(
        %{"type" => "Update", "object" => %{"type" => object_type} = object, "actor" => _actor_id} =
          data
      )
      when object_type in ["Person", "Application", "Service", "Organization"] do
    with {:ok, %Actor{url: url}} <- Actors.get_actor_by_url(object["id"]) do
      {:ok, new_actor_data} = ActivityPub.actor_data_from_actor_object(object)

      Actors.insert_or_update_actor(new_actor_data)

      ActivityPub.update(%{
        local: false,
        to: data["to"] || [],
        cc: data["cc"] || [],
        object: object,
        actor: url
      })
    else
      e ->
        Logger.error(inspect(e))
        :error
    end
  end

  # def handle_incoming(
  #       %{
  #         "type" => "Undo",
  #         "object" => %{"type" => "Announce", "object" => object_id},
  #         "actor" => actor,
  #         "id" => id
  #       } = data
  #     ) do
  #   with actor <- get_actor(data),
  #        {:ok, %Actor{} = actor} <- Actors.get_or_fetch_by_url(actor),
  #        {:ok, object} <- get_obj_helper(object_id) || fetch_obj_helper(object_id),
  #        {:ok, activity, _} <- ActivityPub.unannounce(actor, object, id, false) do
  #     {:ok, activity}
  #   else
  #     _e -> :error
  #   end
  # end

  def handle_incoming(
        %{
          "type" => "Undo",
          "object" => %{"type" => "Follow", "object" => followed},
          "actor" => follower,
          "id" => id
        } = _data
      ) do
    with {:ok, %Actor{domain: nil} = followed} <- Actors.get_actor_by_url(followed),
         {:ok, %Actor{} = follower} <- Actors.get_actor_by_url(follower),
         {:ok, activity} <- ActivityPub.unfollow(followed, follower, id, false) do
      Actor.unfollow(follower, followed)
      {:ok, activity}
    else
      e ->
        Logger.error(inspect(e))
        :error
    end
  end

  # TODO: We presently assume that any actor on the same origin domain as the object being
  # deleted has the rights to delete that object.  A better way to validate whether or not
  # the object should be deleted is to refetch the object URI, which should return either
  # an error or a tombstone.  This would allow us to verify that a deletion actually took
  # place.
  def handle_incoming(
        %{"type" => "Delete", "object" => object, "actor" => _actor, "id" => _id} = data
      ) do
    object_id = Utils.get_url(object)

    with actor <- get_actor(data),
         {:ok, %Actor{url: _actor_url}} <- Actors.get_actor_by_url(actor),
         {:ok, object} <- get_obj_helper(object_id) || fetch_obj_helper(object_id),
         #  TODO : Validate that DELETE comes indeed form right domain (see above)
         #  :ok <- contain_origin(actor_url, object.data),
         {:ok, activity} <- ActivityPub.delete(object, false) do
      {:ok, activity}
    else
      e ->
        Logger.debug(inspect(e))
        :error
    end
  end

  #
  #  # TODO
  #  # Accept
  #  # Undo
  #
  # def handle_incoming(
  #       %{
  #         "type" => "Undo",
  #         "object" => %{"type" => "Like", "object" => object_id},
  #         "actor" => _actor,
  #         "id" => id
  #       } = data
  #     ) do
  #   with actor <- get_actor(data),
  #        %Actor{} = actor <- Actors.get_or_fetch_by_url(actor),
  #        {:ok, object} <- get_obj_helper(object_id) || fetch_obj_helper(object_id),
  #        {:ok, activity, _, _} <- ActivityPub.unlike(actor, object, id, false) do
  #     {:ok, activity}
  #   else
  #     _e -> :error
  #   end
  # end

  def handle_incoming(_) do
    Logger.info("Handing something not supported")
    {:error, :not_supported}
  end

  def set_reply_to_uri(%{"inReplyTo" => in_reply_to} = object) do
    with false <- String.starts_with?(in_reply_to, "http"),
         {:ok, replied_to_object} <- fetch_obj_helper(in_reply_to) do
      Map.put(object, "inReplyTo", replied_to_object["external_url"] || in_reply_to)
    else
      _e -> object
    end
  end

  def set_reply_to_uri(obj), do: obj
  #
  #  # Prepares the object of an outgoing create activity.
  def prepare_object(object) do
    object
    #    |> set_sensitive
    |> add_hashtags
    |> add_mention_tags
    #    |> add_emoji_tags
    |> add_attributed_to
    #    |> prepare_attachments
    |> set_reply_to_uri
  end

  @doc """
  internal -> Mastodon
  """
  def prepare_outgoing(%{"type" => "Create", "object" => %{"type" => "Note"} = object} = data) do
    Logger.debug("Prepare outgoing for a note creation")

    object =
      object
      |> prepare_object

    data =
      data
      |> Map.put("object", object)
      |> Map.merge(Utils.make_json_ld_header())

    Logger.debug("Finished prepare outgoing for a note creation")

    {:ok, data}
  end

  def prepare_outgoing(%{"type" => _type} = data) do
    data =
      data
      |> Map.merge(Utils.make_json_ld_header())

    {:ok, data}
  end

  # def prepare_outgoing(%Event{} = event) do
  #   event =
  #     event
  #     |> Map.from_struct()
  #     |> Map.drop([:__meta__])
  #     |> Map.put(:"@context", "https://www.w3.org/ns/activitystreams")
  #     |> prepare_object

  #   {:ok, event}
  # end

  # def prepare_outgoing(%Comment{} = comment) do
  #   comment =
  #     comment
  #     |> Map.from_struct()
  #     |> Map.drop([:__meta__])
  #     |> Map.put(:"@context", "https://www.w3.org/ns/activitystreams")
  #     |> prepare_object

  #   {:ok, comment}
  # end

  #
  #  def maybe_fix_object_url(data) do
  #    if is_binary(data["object"]) and not String.starts_with?(data["object"], "http") do
  #      case ActivityPub.fetch_object_from_id(data["object"]) do
  #        {:ok, relative_object} ->
  #          if relative_object.data["external_url"] do
  #            data =
  #              data
  #              |> Map.put("object", relative_object.data["external_url"])
  #          else
  #            data
  #          end
  #
  #        e ->
  #          Logger.error("Couldn't fetch #{data["object"]} #{inspect(e)}")
  #          data
  #      end
  #    else
  #      data
  #    end
  #  end
  #

  def add_hashtags(object) do
    tags =
      (object["tag"] || [])
      |> Enum.map(fn tag ->
        %{
          "href" => MobilizonWeb.Endpoint.url() <> "/tags/#{tag}",
          "name" => "##{tag}",
          "type" => "Hashtag"
        }
      end)

    object
    |> Map.put("tag", tags)
  end

  def add_mention_tags(object) do
    recipients =
      (object["to"] ++ (object["cc"] || [])) -- ["https://www.w3.org/ns/activitystreams#Public"]

    mentions =
      recipients
      |> Enum.filter(& &1)
      |> Enum.map(fn url ->
        case Actors.get_actor_by_url(url) do
          {:ok, actor} -> actor
          _ -> nil
        end
      end)
      |> Enum.filter(& &1)
      |> Enum.map(fn actor ->
        %{"type" => "Mention", "href" => actor.url, "name" => "@#{actor.preferred_username}"}
      end)

    tags = object["tag"] || []

    object
    |> Map.put("tag", tags ++ mentions)
  end

  #
  #  # TODO: we should probably send mtime instead of unix epoch time for updated
  #  def add_emoji_tags(object) do
  #    tags = object["tag"] || []
  #    emoji = object["emoji"] || []
  #
  #    out =
  #      emoji
  #      |> Enum.map(fn {name, url} ->
  #        %{
  #          "icon" => %{"url" => url, "type" => "Image"},
  #          "name" => ":" <> name <> ":",
  #          "type" => "Emoji",
  #          "updated" => "1970-01-01T00:00:00Z",
  #          "id" => url
  #        }
  #      end)
  #
  #    object
  #    |> Map.put("tag", tags ++ out)
  #  end
  #

  #
  #  def set_sensitive(object) do
  #    tags = object["tag"] || []
  #    Map.put(object, "sensitive", "nsfw" in tags)
  #  end
  #
  def add_attributed_to(object) do
    attributed_to = object["attributedTo"] || object["actor"]

    object |> Map.put("attributedTo", attributed_to)
  end

  #
  #  def prepare_attachments(object) do
  #    attachments =
  #      (object["attachment"] || [])
  #      |> Enum.map(fn data ->
  #        [%{"mediaType" => media_type, "href" => href} | _] = data["url"]
  #        %{"url" => href, "mediaType" => media_type, "name" => data["name"], "type" => "Document"}
  #      end)
  #
  #    object
  #    |> Map.put("attachment", attachments)
  #  end

  @spec fetch_obj_helper(String.t()) :: {:ok, %Event{}} | {:ok, %Comment{}} | {:error, any()}
  def fetch_obj_helper(url) when is_bitstring(url), do: ActivityPub.fetch_object_from_url(url)

  @spec fetch_obj_helper(map()) :: {:ok, %Event{}} | {:ok, %Comment{}} | {:error, any()}
  def fetch_obj_helper(obj) when is_map(obj), do: ActivityPub.fetch_object_from_url(obj["id"])

  @spec get_obj_helper(String.t()) :: {:ok, struct()} | nil
  def get_obj_helper(id) do
    if object = normalize(id), do: {:ok, object}, else: nil
  end

  @spec normalize(map()) :: struct() | nil
  def normalize(obj) when is_map(obj), do: get_anything_by_url(obj["id"])
  @spec normalize(String.t()) :: struct() | nil
  def normalize(url) when is_binary(url), do: get_anything_by_url(url)
  @spec normalize(any()) :: nil
  def normalize(_), do: nil

  @spec normalize(String.t()) :: struct() | nil
  def get_anything_by_url(url) do
    Logger.debug("Getting anything from url #{url}")
    get_actor_url(url) || get_event_url(url) || get_comment_url(url)
  end

  defp get_actor_url(url) do
    case Actors.get_actor_by_url(url) do
      {:ok, %Actor{} = actor} -> actor
      _ -> nil
    end
  end

  defp get_event_url(url) do
    case Events.get_event_by_url(url) do
      {:ok, %Event{} = event} -> event
      _ -> nil
    end
  end

  defp get_comment_url(url) do
    case Events.get_comment_full_from_url(url) do
      {:ok, %Comment{} = comment} -> comment
      _ -> nil
    end
  end
end
