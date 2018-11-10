defmodule Mobilizon.Service.ActivityPub.Transmogrifier do
  @moduledoc """
  A module to handle coding from internal to wire ActivityPub and back.
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors
  alias Mobilizon.Events.{Event, Comment}
  alias Mobilizon.Service.ActivityPub

  import Ecto.Query

  require Logger

  @doc """
  Modifies an incoming AP object (mastodon format) to our internal format.
  """
  def fix_object(object) do
    object
    |> Map.put("actor", object["attributedTo"])
    |> fix_attachments
    # |> fix_in_reply_to
    |> fix_tag
  end

  #  def fix_in_reply_to(%{"inReplyTo" => in_reply_to_id} = object)
  #      when not is_nil(in_reply_to_id) do
  #    case ActivityPub.fetch_object_from_id(in_reply_to_id) do
  #      {:ok, replied_object} ->
  #        activity = Activity.get_create_activity_by_object_ap_id(replied_object.data["id"])
  #
  #        object
  #        |> Map.put("inReplyTo", replied_object.data["id"])
  #
  #      e ->
  #        Logger.error("Couldn't fetch #{object["inReplyTo"]} #{inspect(e)}")
  #        object
  #    end
  #  end

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
      object = fix_object(data["object"])

      params = %{
        to: data["to"],
        object: object,
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
    with {:ok, %Actor{} = followed} <- Actors.get_or_fetch_by_url(followed),
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
  #           get_obj_helper(object_id) || ActivityPub.fetch_object_from_id(object_id),
  #         {:ok, activity, object} <- ActivityPub.like(actor, object, id, false) do
  #      {:ok, activity}
  #    else
  #      _e -> :error
  #    end
  #  end
  #
  def handle_incoming(
        %{"type" => "Announce", "object" => object_id, "actor" => actor, "id" => id} = data
      ) do
    with {:ok, %Actor{} = actor} <- Actors.get_or_fetch_by_url(actor),
         {:ok, object} <-
           get_obj_helper(object_id) || ActivityPub.fetch_event_from_url(object_id),
         {:ok, activity, object} <- ActivityPub.announce(actor, object, id, false) do
      {:ok, activity}
    else
      _e -> :error
    end
  end

  #
  #  def handle_incoming(
  #        %{"type" => "Update", "object" => %{"type" => "Person"} = object, "actor" => actor_id} =
  #          data
  #      ) do
  #    with %User{ap_id: ^actor_id} = actor <- User.get_by_ap_id(object["id"]) do
  #      {:ok, new_user_data} = ActivityPub.user_data_from_user_object(object)
  #
  #      banner = new_user_data[:info]["banner"]
  #
  #      update_data =
  #        new_user_data
  #        |> Map.take([:name, :bio, :avatar])
  #        |> Map.put(:info, Map.merge(actor.info, %{"banner" => banner}))
  #
  #      actor
  #      |> User.upgrade_changeset(update_data)
  #      |> User.update_and_set_cache()
  #
  #      ActivityPub.update(%{
  #        local: false,
  #        to: data["to"] || [],
  #        cc: data["cc"] || [],
  #        object: object,
  #        actor: actor_id
  #      })
  #    else
  #      e ->
  #        Logger.error(e)
  #        :error
  #    end
  #  end
  #
  #  # TODO: Make secure.
  #  def handle_incoming(
  #        %{"type" => "Delete", "object" => object_id, "actor" => actor, "id" => id} = data
  #      ) do
  #    object_id =
  #      case object_id do
  #        %{"id" => id} -> id
  #        id -> id
  #      end
  #
  #    with %User{} = actor <- User.get_or_fetch_by_ap_id(actor),
  #         {:ok, object} <-
  #           get_obj_helper(object_id) || ActivityPub.fetch_object_from_id(object_id),
  #         {:ok, activity} <- ActivityPub.delete(object, false) do
  #      {:ok, activity}
  #    else
  #      e -> :error
  #    end
  #  end
  #
  #  # TODO
  #  # Accept
  #  # Undo
  #
  def handle_incoming(_), do: :error

  def get_obj_helper(id) do
    if object = Object.get_by_ap_id(id), do: {:ok, object}, else: nil
  end

  def set_reply_to_uri(%{"inReplyTo" => in_reply_to} = object) do
    with false <- String.starts_with?(in_reply_to, "http"),
         {:ok, %{data: replied_to_object}} <- get_obj_helper(in_reply_to) do
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
    #    |> add_hashtags
    |> add_mention_tags
    #    |> add_emoji_tags
    |> add_attributed_to
    #    |> prepare_attachments
    |> set_reply_to_uri
  end

  @doc
  """
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
      |> Map.put("@context", "https://www.w3.org/ns/activitystreams")

    Logger.debug("Finished prepare outgoing for a note creation")

    {:ok, data}
  end

  def prepare_outgoing(%{"type" => type} = data) do
    data =
      data
      # |> maybe_fix_object_url
      |> Map.put("@context", "https://www.w3.org/ns/activitystreams")

    {:ok, data}
  end

  def prepare_outgoing(%Event{} = event) do
    event =
      event
      |> Map.from_struct()
      |> Map.drop([:__meta__])
      |> Map.put(:"@context", "https://www.w3.org/ns/activitystreams")
      |> prepare_object

    {:ok, event}
  end

  def prepare_outgoing(%Comment{} = comment) do
    comment =
      comment
      |> Map.from_struct()
      |> Map.drop([:__meta__])
      |> Map.put(:"@context", "https://www.w3.org/ns/activitystreams")
      |> prepare_object

    {:ok, comment}
  end

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
  def add_mention_tags(object) do
    recipients = object["to"] ++ (object["cc"] || [])

    mentions =
      recipients
      |> Enum.map(fn url -> Actors.get_actor_by_url!(url) end)
      |> Enum.filter(& &1)
      |> Enum.map(fn actor ->
        %{"type" => "Mention", "href" => actor.url, "name" => "@#{actor.preferredUsername}"}
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
end
