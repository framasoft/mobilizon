# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/utils.ex

defmodule Mobilizon.Service.ActivityPub.Utils do
  @moduledoc """
  # Utils

  Various utils
  """

  alias Ecto.Changeset

  alias Mobilizon.Addresses
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Comment, Event}
  alias Mobilizon.Media.Picture
  alias Mobilizon.Reports
  alias Mobilizon.Reports.Report
  alias Mobilizon.Service.ActivityPub.{Activity, Converters}
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users

  alias MobilizonWeb.{Email, Endpoint}
  alias MobilizonWeb.Router.Helpers, as: Routes

  require Logger

  @actor_types ["Group", "Person", "Application"]

  # Some implementations send the actor URI as the actor field, others send the entire actor object,
  # so figure out what the actor's URI is based on what we have.
  def get_url(%{"id" => id}), do: id
  def get_url(id) when is_bitstring(id), do: id
  def get_url(_), do: nil

  def make_json_ld_header do
    %{
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://litepub.github.io/litepub/context.jsonld",
        %{
          "sc" => "http://schema.org#",
          "Hashtag" => "as:Hashtag",
          "category" => "sc:category",
          "uuid" => "sc:identifier"
        }
      ]
    }
  end

  def make_date do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end

  @doc """
  Enqueues an activity for federation if it's local
  """
  def maybe_federate(%Activity{local: true} = activity) do
    Logger.debug("Maybe federate an activity")

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

  def remote_actors(%{data: %{"to" => to} = data}) do
    to = to ++ (data["cc"] || [])

    to
    |> Enum.map(fn url -> Actors.get_actor_by_url(url) end)
    |> Enum.map(fn {status, actor} ->
      case status do
        :ok ->
          actor

        _ ->
          nil
      end
    end)
    |> Enum.map(& &1)
    |> Enum.filter(fn actor -> actor && !is_nil(actor.domain) end)
  end

  @doc """
  Adds an id and a published data if they aren't there,
  also adds it to an included object
  """
  def lazy_put_activity_defaults(map) do
    if is_map(map["object"]) do
      object = lazy_put_object_defaults(map["object"])
      %{map | "object" => object}
    else
      map
    end
  end

  @doc """
  Adds an id and published date if they aren't there.
  """
  def lazy_put_object_defaults(map) do
    Map.put_new_lazy(map, "published", &make_date/0)
  end

  @doc """
  Inserts a full object if it is contained in an activity.
  """
  def insert_full_object(object_data)

  @doc """
  Inserts a full object if it is contained in an activity.
  """
  def insert_full_object(%{"object" => %{"type" => "Event"} = object_data, "type" => "Create"})
      when is_map(object_data) do
    with {:ok, object_data} <-
           Converters.Event.as_to_model_data(object_data),
         {:ok, %Event{} = event} <- Events.create_event(object_data) do
      {:ok, event}
    end
  end

  def insert_full_object(%{"object" => %{"type" => "Group"} = object_data, "type" => "Create"})
      when is_map(object_data) do
    with object_data <-
           Map.put(object_data, "preferred_username", object_data["preferredUsername"]),
         {:ok, %Actor{} = group} <- Actors.create_group(object_data) do
      {:ok, group}
    end
  end

  @doc """
  Inserts a full object if it is contained in an activity.
  """
  def insert_full_object(%{"object" => %{"type" => "Note"} = object_data, "type" => "Create"})
      when is_map(object_data) do
    with data <- Converters.Comment.as_to_model_data(object_data),
         {:ok, %Comment{} = comment} <- Events.create_comment(data) do
      {:ok, comment}
    else
      err ->
        Logger.error("Error while inserting a remote comment inside database")
        Logger.debug(inspect(err))
        {:error, err}
    end
  end

  @doc """
  Inserts a full object if it is contained in an activity.
  """
  def insert_full_object(%{"type" => "Flag"} = object_data)
      when is_map(object_data) do
    with data <- Converters.Flag.as_to_model_data(object_data),
         {:ok, %Report{} = report} <- Reports.create_report(data) do
      Enum.each(Users.list_moderators(), fn moderator ->
        moderator
        |> Email.Admin.report(report)
        |> Email.Mailer.deliver_later()
      end)

      {:ok, report}
    else
      err ->
        Logger.error("Error while inserting report inside database")
        Logger.debug(inspect(err))
        {:error, err}
    end
  end

  def insert_full_object(_), do: {:ok, nil}

  @doc """
  Update an object
  """
  @spec update_object(struct(), map()) :: {:ok, struct()} | any()
  def update_object(object, object_data)

  def update_object(event_url, %{
        "object" => %{"type" => "Event"} = object_data,
        "type" => "Update"
      })
      when is_map(object_data) do
    with {:event_not_found, %Event{} = event} <-
           {:event_not_found, Events.get_event_by_url(event_url)},
         {:ok, object_data} <- Converters.Event.as_to_model_data(object_data),
         {:ok, %Event{} = event} <- Events.update_event(event, object_data) do
      {:ok, event}
    end
  end

  def update_object(actor_url, %{
        "object" => %{"type" => type_actor} = object_data,
        "type" => "Update"
      })
      when is_map(object_data) and type_actor in @actor_types do
    with {:ok, %Actor{} = actor} <- Actors.get_actor_by_url(actor_url),
         object_data <- Converters.Actor.as_to_model_data(object_data),
         {:ok, %Actor{} = actor} <- Actors.update_actor(actor, object_data) do
      {:ok, actor}
    end
  end

  def update_object(_, _), do: {:ok, nil}

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

  @doc """
  Save picture data from %Plug.Upload{} and return AS Link data.
  """
  def make_picture_data(%Plug.Upload{} = picture) do
    case MobilizonWeb.Upload.store(picture) do
      {:ok, picture} ->
        picture

      _ ->
        nil
    end
  end

  @doc """
  Convert a picture model into an AS Link representation
  """
  # TODO: Move me to Mobilizon.Service.ActivityPub.Converters
  def make_picture_data(%Picture{file: file} = _picture) do
    %{
      "type" => "Document",
      "url" => [
        %{
          "type" => "Link",
          "mediaType" => file.content_type,
          "href" => file.url
        }
      ],
      "name" => file.name
    }
  end

  @doc """
  Save picture data from raw data and return AS Link data.
  """
  def make_picture_data(picture) when is_map(picture) do
    with {:ok, %{"url" => [%{"href" => url, "mediaType" => content_type}], "size" => size}} <-
           MobilizonWeb.Upload.store(picture.file),
         {:ok, %Picture{file: _file} = pic} <-
           Mobilizon.Media.create_picture(%{
             "file" => %{
               "url" => url,
               "name" => picture.name,
               "content_type" => content_type,
               "size" => size
             },
             "actor_id" => picture.actor_id
           }) do
      make_picture_data(pic)
    end
  end

  def make_picture_data(nil), do: nil

  @doc """
  Make an AP event object from an set of values
  """
  @spec make_event_data(
          String.t(),
          map(),
          String.t(),
          String.t(),
          map(),
          list(),
          map(),
          String.t()
        ) :: map()
  def make_event_data(
        actor,
        %{to: to, cc: cc} = _audience,
        title,
        content_html,
        picture \\ nil,
        tags \\ [],
        metadata \\ %{},
        uuid \\ nil,
        url \\ nil
      ) do
    Logger.debug("Making event data")
    uuid = uuid || Ecto.UUID.generate()

    res = %{
      "type" => "Event",
      "to" => to,
      "cc" => cc || [],
      "content" => content_html,
      "name" => title,
      "startTime" => metadata.begins_on,
      "endTime" => metadata.ends_on,
      "category" => metadata.category,
      "actor" => actor,
      "id" => url || Routes.page_url(Endpoint, :event, uuid),
      "joinOptions" => metadata.join_options,
      "uuid" => uuid,
      "tag" =>
        tags |> Enum.uniq() |> Enum.map(fn tag -> %{"type" => "Hashtag", "name" => "##{tag}"} end)
    }

    res =
      if is_nil(metadata.physical_address),
        do: res,
        else: Map.put(res, "location", make_address_data(metadata.physical_address))

    res =
      if is_nil(picture), do: res, else: Map.put(res, "attachment", [make_picture_data(picture)])

    if is_nil(metadata.options) do
      res
    else
      options = struct(Mobilizon.Events.EventOptions, metadata.options) |> Map.from_struct()

      Enum.reduce(options, res, fn {key, value}, acc ->
        (value && Map.put(acc, camelize(key), value)) ||
          acc
      end)
    end
  end

  def make_address_data(%Address{} = address) do
    #    res = %{
    #      "type" => "Place",
    #      "name" => address.description,
    #      "id" => address.url,
    #      "address" => %{
    #        "type" => "PostalAddress",
    #        "streetAddress" => address.street,
    #        "postalCode" => address.postal_code,
    #        "addressLocality" => address.locality,
    #        "addressRegion" => address.region,
    #        "addressCountry" => address.country
    #      }
    #    }
    #
    #    if is_nil(address.geom) do
    #      res
    #    else
    #      Map.put(res, "geo", %{
    #        "type" => "GeoCoordinates",
    #        "latitude" => address.geom.coordinates |> elem(0),
    #        "longitude" => address.geom.coordinates |> elem(1)
    #      })
    #    end
    address.url
  end

  def make_address_data(address) when is_map(address) do
    Address
    |> struct(address)
    |> make_address_data()
  end

  def make_address_data(address_url) when is_bitstring(address_url) do
    with %Address{} = address <- Addresses.get_address_by_url(address_url) do
      address.url
    end
  end

  @doc """
  Make an AP comment object from an set of values
  """
  def make_comment_data(
        actor,
        to,
        content_html,
        # attachments,
        inReplyTo \\ nil,
        tags \\ [],
        # _cw \\ nil,
        cc \\ []
      ) do
    Logger.debug("Making comment data")
    uuid = Ecto.UUID.generate()

    object = %{
      "type" => "Note",
      "to" => to,
      "cc" => cc,
      "content" => content_html,
      # "summary" => cw,
      # "attachment" => attachments,
      "actor" => actor,
      "id" => Routes.page_url(Endpoint, :comment, uuid),
      "uuid" => uuid,
      "tag" => tags |> Enum.uniq()
    }

    if inReplyTo do
      object
      |> Map.put("inReplyTo", inReplyTo)
    else
      object
    end
  end

  def make_group_data(
        actor,
        to,
        preferred_username,
        content_html,
        # attachments,
        tags \\ [],
        # _cw \\ nil,
        cc \\ []
      ) do
    uuid = Ecto.UUID.generate()

    %{
      "type" => "Group",
      "to" => to,
      "cc" => cc,
      "summary" => content_html,
      "attributedTo" => actor,
      "preferredUsername" => preferred_username,
      "id" => Actor.build_url(preferred_username, :page),
      "uuid" => uuid,
      "tag" => tags |> Enum.map(fn {_, tag} -> tag end) |> Enum.uniq()
    }
  end

  #### Like-related helpers

  @doc """
  Returns an existing like if a user already liked an object
  """
  # @spec get_existing_like(Actor.t, map()) :: nil
  # def get_existing_like(%Actor{url: url} = actor, %{data: %{"id" => id}}) do
  #   nil
  # end

  # def make_like_data(%Actor{url: url} = actor, %{data: %{"id" => id}} = object, activity_id) do
  #   data = %{
  #     "type" => "Like",
  #     "actor" => url,
  #     "object" => id,
  #     "to" => [actor.followers_url, object.data["actor"]],
  #     "cc" => ["https://www.w3.org/ns/activitystreams#Public"],
  #     "context" => object.data["context"]
  #   }

  #   if activity_id, do: Map.put(data, "id", activity_id), else: data
  # end

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
  Makes a follow activity data for the given followed and follower
  """
  def make_follow_data(%Actor{url: followed_id}, %Actor{url: follower_id}, activity_id) do
    Logger.debug("Make follow data")

    data = %{
      "type" => "Follow",
      "actor" => follower_id,
      "to" => [followed_id],
      "cc" => ["https://www.w3.org/ns/activitystreams#Public"],
      "object" => followed_id
    }

    data =
      if activity_id,
        do: Map.put(data, "id", activity_id),
        else: data

    Logger.debug(inspect(data))

    data
  end

  #### Announce-related helpers

  require Logger

  @doc """
  Make announce activity data for the given actor and object
  """
  def make_announce_data(actor, object, activity_id, public \\ true)

  def make_announce_data(
        %Actor{url: actor_url, followers_url: actor_followers_url} = _actor,
        %{"id" => url, "type" => type} = _object,
        activity_id,
        public
      )
      when type in @actor_types do
    do_make_announce_data(actor_url, actor_followers_url, url, url, activity_id, public)
  end

  def make_announce_data(
        %Actor{url: actor_url, followers_url: actor_followers_url} = _actor,
        %{"id" => url, "type" => type, "actor" => object_actor_url} = _object,
        activity_id,
        public
      )
      when type in ["Note", "Event"] do
    do_make_announce_data(
      actor_url,
      actor_followers_url,
      object_actor_url,
      url,
      activity_id,
      public
    )
  end

  defp do_make_announce_data(
         actor_url,
         actor_followers_url,
         object_actor_url,
         object_url,
         activity_id,
         public
       ) do
    {to, cc} =
      if public do
        {[actor_followers_url, object_actor_url],
         ["https://www.w3.org/ns/activitystreams#Public"]}
      else
        {[actor_followers_url], []}
      end

    data = %{
      "type" => "Announce",
      "actor" => actor_url,
      "object" => object_url,
      "to" => to,
      "cc" => cc
    }

    if activity_id, do: Map.put(data, "id", activity_id), else: data
  end

  @doc """
  Make unannounce activity data for the given actor and object
  """
  def make_unannounce_data(
        %Actor{url: url} = actor,
        activity,
        activity_id
      ) do
    data = %{
      "type" => "Undo",
      "actor" => url,
      "object" => activity,
      "to" => [actor.followers_url, actor.url],
      "cc" => ["https://www.w3.org/ns/activitystreams#Public"]
    }

    if activity_id, do: Map.put(data, "id", activity_id), else: data
  end

  #### Unfollow-related helpers

  @spec make_unfollow_data(Actor.t(), Actor.t(), map(), String.t()) :: map()
  def make_unfollow_data(
        %Actor{url: follower_url},
        %Actor{url: followed_url},
        follow_activity,
        activity_id
      ) do
    data = %{
      "type" => "Undo",
      "actor" => follower_url,
      "to" => [followed_url],
      "object" => follow_activity.data
    }

    if activity_id, do: Map.put(data, "id", activity_id), else: data
  end

  #### Create-related helpers

  @doc """
  Make create activity data
  """
  @spec make_create_data(map(), map()) :: map()
  def make_create_data(params, additional \\ %{}) do
    Logger.debug("Making create data")
    Logger.debug(inspect(params))
    published = params.published || make_date()

    %{
      "type" => "Create",
      "to" => params.to |> Enum.uniq(),
      "actor" => params.actor.url,
      "object" => params.object,
      "published" => published,
      "id" => params.object["id"] <> "/activity"
    }
    |> Map.merge(additional)
  end

  #### Flag-related helpers
  @spec make_flag_data(map(), map()) :: map()
  def make_flag_data(params, additional) do
    object = [params.reported_actor_url] ++ params.comments_url

    object = if params[:event_url], do: object ++ [params.event_url], else: object

    %{
      "type" => "Flag",
      "id" => "#{MobilizonWeb.Endpoint.url()}/report/#{Ecto.UUID.generate()}",
      "actor" => params.reporter_url,
      "content" => params.content,
      "object" => object,
      "state" => "open"
    }
    |> Map.merge(additional)
  end

  def make_join_data(%Event{} = event, %Actor{} = actor) do
    %{
      "type" => "Join",
      "id" => "#{actor.url}/join/event/id",
      "actor" => actor.url,
      "object" => event.url
    }
  end

  def make_join_data(%Actor{type: :Group} = event, %Actor{} = actor) do
    %{
      "type" => "Join",
      "id" => "#{actor.url}/join/group/id",
      "actor" => actor.url,
      "object" => event.url
    }
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

  def camelize(word) when is_atom(word) do
    camelize(to_string(word))
  end

  def camelize(word) when is_bitstring(word) do
    {first, rest} = String.split_at(Macro.camelize(word), 1)
    String.downcase(first) <> rest
  end

  def underscore(word) when is_atom(word) do
    underscore(to_string(word))
  end

  def underscore(word) when is_bitstring(word) do
    Macro.underscore(word)
  end
end
