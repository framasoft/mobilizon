defmodule Mobilizon.Service.ActivityPub.Utils do
  @moduledoc """
  # Utils

  Various utils
  """

  alias Mobilizon.Repo
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Events
  alias Mobilizon.Activity
  alias MobilizonWeb
  alias MobilizonWeb.Router.Helpers
  alias MobilizonWeb.Endpoint
  alias Ecto.{Changeset, UUID}
  import Ecto.Query

  def make_json_ld_header do
    %{
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        %{
          "manuallyApprovesFollowers" => "as:manuallyApprovesFollowers",
          "sensitive" => "as:sensitive",
          "Hashtag" => "as:Hashtag",
          "toot" => "http://joinmastodon.org/ns#",
          "Emoji" => "toot:Emoji"
        }
      ]
    }
  end

  def make_date do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end

  def generate_activity_id do
    generate_id("activities")
  end

  def generate_context_id do
    generate_id("contexts")
  end

  #  def generate_object_id do
  #    Helpers.o_status_url(Endpoint, :object, UUID.generate())
  #  end

  def generate_id(type) do
    "#{MobilizonWeb.Endpoint.url()}/#{type}/#{UUID.generate()}"
  end

  #  def create_context(context) do
  #    context = context || generate_id("contexts")
  #    changeset = Object.context_mapping(context)
  #
  #    case Repo.insert(changeset) do
  #      {:ok, object} ->
  #        object
  #
  #      # This should be solved by an upsert, but it seems ecto
  #      # has problems accessing the constraint inside the jsonb.
  #      {:error, _} ->
  #        Events.get_cached_by_url(context)
  #    end
  #  end

  @doc """
  Enqueues an activity for federation if it's local
  """
  def maybe_federate(%Activity{local: true} = activity) do
    priority =
      case activity.data["type"] do
        "Delete" -> 10
        "Create" -> 1
        _ -> 5
      end

    Mobilizon.Service.Federator.enqueue(:publish, activity, priority)
    :ok
  end

  def maybe_federate(_), do: :ok

  @doc """
  Adds an id and a published data if they aren't there,
  also adds it to an included object
  """
  def lazy_put_activity_defaults(map) do
    #    %{data: %{"id" => context}, id: context_id} = create_context(map["context"])
    #
    #    map =
    #      map
    #      |> Map.put_new_lazy("id", &generate_activity_id/0)
    #      |> Map.put_new_lazy("published", &make_date/0)
    #      |> Map.put_new("context", context)
    #      |> Map.put_new("context_id", context_id)

    if is_map(map["object"]) do
      object = lazy_put_object_defaults(map["object"], map)
      %{map | "object" => object}
    else
      map
    end
  end

  @doc """
  Adds an id and published date if they aren't there.
  """
  def lazy_put_object_defaults(map, activity \\ %{}) do
    map
    # |> Map.put_new_lazy("id", &generate_object_id/0)
    |> Map.put_new_lazy("published", &make_date/0)
    |> Map.put_new("context", activity["context"])
    |> Map.put_new("context_id", activity["context_id"])
  end

  @doc """
  Inserts a full object if it is contained in an activity.
  """
  def insert_full_object(%{"object" => %{"type" => type} = object_data})
      when is_map(object_data) and type == "Event" do
    with {:ok, _} <- Events.create_event(object_data) do
      :ok
    end
  end

  @doc """
  Inserts a full object if it is contained in an activity.
  """
  def insert_full_object(%{"object" => %{"type" => type} = object_data})
      when is_map(object_data) and type == "Note" do
    with {:ok, %Actor{id: actor_id}} <- Actors.get_or_fetch_by_url(object_data["actor"]) do
      data = %{
        "text" => object_data["content"],
        "url" => object_data["id"],
        "actor_id" => actor_id,
        "in_reply_to_comment_id" => object_data["inReplyTo"],
        # probably
        "local" => false
      }

      require Logger
      Logger.info("comment data ready to be inserted")
      Logger.info(inspect(data))

      with {:ok, comm} <- Events.create_comment(data) do
        Logger.info("comment inserted")
        Logger.info(inspect(comm))
        :ok
      else
        err ->
          Logger.error("Error while inserting a remote comment inside database")
          Logger.error(inspect err)
          {:error, err}
      end
    end
  end

  def insert_full_object(_), do: :ok

  #  def update_object_in_activities(%{data: %{"id" => id}} = object) do
  #    # TODO
  #    # Update activities that already had this. Could be done in a seperate process.
  #    # Alternatively, just don't do this and fetch the current object each time. Most
  #    # could probably be taken from cache.
  #    relevant_activities = Activity.all_by_object_url(id)
  #
  #    Enum.map(relevant_activities, fn activity ->
  #      new_activity_data = activity.data |> Map.put("object", object.data)
  #      changeset = Changeset.change(activity, data: new_activity_data)
  #      Repo.update(changeset)
  #    end)
  #  end

  #### Like-related helpers

  #  @doc """
  #  Returns an existing like if a user already liked an object
  #  """
  #  def get_existing_like(actor, %{data: %{"id" => id}}) do
  #    query =
  #      from(
  #        activity in Activity,
  #        where: fragment("(?)->>'actor' = ?", activity.data, ^actor),
  #        # this is to use the index
  #        where:
  #          fragment(
  #            "coalesce((?)->'object'->>'id', (?)->>'object') = ?",
  #            activity.data,
  #            activity.data,
  #            ^id
  #          ),
  #        where: fragment("(?)->>'type' = 'Like'", activity.data)
  #      )
  #
  #    Repo.one(query)
  #  end

  def make_comment_data(
        actor,
        to,
        context,
        content_html,
        attachments,
        inReplyTo,
        tags,
        cw \\ nil,
        cc \\ []
      ) do
    object = %{
      "type" => "Note",
      "to" => to,
      "cc" => cc,
      "content" => content_html,
      "summary" => cw,
      "context" => context,
      "attachment" => attachments,
      "actor" => actor,
      "tag" => tags |> Enum.map(fn {_, tag} -> tag end) |> Enum.uniq()
    }

    if inReplyTo do
      object
      |> Map.put("inReplyTo", inReplyTo.data["object"]["id"])
      |> Map.put("inReplyToStatusId", inReplyTo.id)
    else
      object
    end
  end

  def make_create_data(params, additional) do
    published = params.published || make_date()

    %{
      "type" => "Create",
      "to" => params.to |> Enum.uniq(),
      "actor" => params.actor.ap_id,
      "object" => params.object,
      "published" => published,
      "context" => params.context
    }
    |> Map.merge(additional)
  end

  def make_like_data(%Actor{url: url} = actor, %{data: %{"id" => id}} = object, activity_id) do
    data = %{
      "type" => "Like",
      "actor" => url,
      "object" => id,
      "to" => [actor.follower_address, object.data["actor"]],
      "cc" => ["https://www.w3.org/ns/activitystreams#Public"],
      "context" => object.data["context"]
    }

    if activity_id, do: Map.put(data, "id", activity_id), else: data
  end

  def update_element_in_object(property, element, object) do
    with new_data <-
           object.data
           |> Map.put("#{property}_count", length(element))
           |> Map.put("#{property}s", element),
         changeset <- Changeset.change(object, data: new_data),
         {:ok, object} <- Repo.update(changeset) do
      {:ok, object}
    end
  end

  #  def update_likes_in_object(likes, object) do
  #    update_element_in_object("like", likes, object)
  #  end
  #
  #  def add_like_to_object(%Activity{data: %{"actor" => actor}}, object) do
  #    with likes <- [actor | object.data["likes"] || []] |> Enum.uniq() do
  #      update_likes_in_object(likes, object)
  #    end
  #  end
  #
  #  def remove_like_from_object(%Activity{data: %{"actor" => actor}}, object) do
  #    with likes <- (object.data["likes"] || []) |> List.delete(actor) do
  #      update_likes_in_object(likes, object)
  #    end
  #  end

  #### Follow-related helpers

  @doc """
  Makes a follow activity data for the given follower and followed
  """
  def make_follow_data(%Actor{url: follower_id}, %Actor{url: followed_id}, activity_id) do
    data = %{
      "type" => "Follow",
      "actor" => follower_id,
      "to" => [followed_id],
      "cc" => ["https://www.w3.org/ns/activitystreams#Public"],
      "object" => followed_id
    }

    if activity_id, do: Map.put(data, "id", activity_id), else: data
  end

  #  def fetch_latest_follow(%Actor{url: follower_id}, %Actor{url: followed_id}) do
  #    query =
  #      from(
  #        activity in Activity,
  #        where:
  #          fragment(
  #            "? @> ?",
  #            activity.data,
  #            ^%{type: "Follow", actor: follower_id, object: followed_id}
  #          ),
  #        order_by: [desc: :id],
  #        limit: 1
  #      )
  #
  #    Repo.one(query)
  #  end

  #### Announce-related helpers

  @doc """
  Make announce activity data for the given actor and object
  """
  def make_announce_data(
        %Actor{url: url} = user,
        %Event{id: id} = object,
        activity_id
      ) do
    data = %{
      "type" => "Announce",
      "actor" => url,
      "object" => id,
      "to" => [user.follower_address, object.data["actor"]],
      "cc" => ["https://www.w3.org/ns/activitystreams#Public"],
      "context" => object.data["context"]
    }

    if activity_id, do: Map.put(data, "id", activity_id), else: data
  end

  def add_announce_to_object(%Activity{data: %{"actor" => actor}}, object) do
    with announcements <- [actor | object.data["announcements"] || []] |> Enum.uniq() do
      update_element_in_object("announcement", announcements, object)
    end
  end

  #### Unfollow-related helpers

  def make_unfollow_data(follower, followed, follow_activity) do
    %{
      "type" => "Undo",
      "actor" => follower.url,
      "to" => [followed.url],
      "object" => follow_activity.data["id"]
    }
  end

  #### Create-related helpers

  def make_create_data(params, additional) do
    published = params.published || make_date()

    %{
      "type" => "Create",
      "to" => params.to |> Enum.uniq(),
      "actor" => params.actor.url,
      "object" => params.object,
      "published" => published,
      "context" => params.context
    }
    |> Map.merge(additional)
  end

  @doc """
  Converts PEM encoded keys to a public key representation
  """
  def pem_to_public_key(pem) do
    [key_code] = :public_key.pem_decode(pem)
    key = :public_key.pem_entry_decode(key_code)

    case key do
      {:RSAPrivateKey, _, modulus, exponent, _, _, _, _, _, _, _} ->
        {:RSAPublicKey, modulus, exponent}

      {:RSAPublicKey, modulus, exponent} ->
        {:RSAPublicKey, modulus, exponent}
    end
  end

  @doc """
  Converts PEM encoded keys to a private key representation
  """
  def pem_to_private_key(pem) do
    [private_key_code] = :public_key.pem_decode(pem)
    :public_key.pem_entry_decode(private_key_code)
  end

  @doc """
  Converts PEM encoded keys to a PEM public key representation
  """
  def pem_to_public_key_pem(pem) do
    public_key = pem_to_public_key(pem)
    public_key = :public_key.pem_entry_encode(:RSAPublicKey, public_key)
    :public_key.pem_encode([public_key])
  end
end
