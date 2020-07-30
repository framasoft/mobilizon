# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/utils.ex

defmodule Mobilizon.Federation.ActivityPub.Utils do
  @moduledoc """
  Various ActivityPub related utils.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Media.Picture

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Activity, Federator, Relay}
  alias Mobilizon.Federation.ActivityPub.Types.Ownable
  alias Mobilizon.Federation.ActivityStream.Converter
  alias Mobilizon.Federation.HTTPSignatures
  alias Mobilizon.Web.Endpoint

  require Logger

  @actor_types ["Group", "Person", "Application"]

  # Some implementations send the actor URI as the actor field, others send the entire actor object,
  # so figure out what the actor's URI is based on what we have.
  def get_url(%{"id" => id}), do: id
  def get_url(id) when is_bitstring(id), do: id
  def get_url(ids) when is_list(ids), do: get_url(hd(ids))
  def get_url(_), do: nil

  def make_json_ld_header do
    %{
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://litepub.social/litepub/context.jsonld",
        %{
          "sc" => "http://schema.org#",
          "ical" => "http://www.w3.org/2002/12/cal/ical#",
          "pt" => "https://joinpeertube.org/ns#",
          "Hashtag" => "as:Hashtag",
          "category" => "sc:category",
          "uuid" => "sc:identifier",
          "maximumAttendeeCapacity" => "sc:maximumAttendeeCapacity",
          "location" => %{
            "@id" => "sc:location",
            "@type" => "sc:Place"
          },
          "PostalAddress" => "sc:PostalAddress",
          "address" => %{
            "@id" => "sc:address",
            "@type" => "sc:PostalAddress"
          },
          "addressCountry" => "sc:addressCountry",
          "addressRegion" => "sc:addressRegion",
          "postalCode" => "sc:postalCode",
          "addressLocality" => "sc:addressLocality",
          "streetAddress" => "sc:streetAddress",
          "mz" => "https://joinmobilizon.org/ns#",
          "repliesModerationOptionType" => %{
            "@id" => "mz:repliesModerationOptionType",
            "@type" => "rdfs:Class"
          },
          "repliesModerationOption" => %{
            "@id" => "mz:repliesModerationOption",
            "@type" => "mz:repliesModerationOptionType"
          },
          "commentsEnabled" => %{
            "@type" => "sc:Boolean",
            "@id" => "pt:commentsEnabled"
          },
          "joinModeType" => %{
            "@id" => "mz:joinModeType",
            "@type" => "rdfs:Class"
          },
          "joinMode" => %{
            "@id" => "mz:joinMode",
            "@type" => "mz:joinModeType"
          },
          "anonymousParticipationEnabled" => %{
            "@id" => "mz:anonymousParticipationEnabled",
            "@type" => "sc:Boolean"
          },
          "participationMessage" => %{
            "@id" => "mz:participationMessage",
            "@type" => "sc:Text"
          }
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

    if Mobilizon.Config.get!([:instance, :federating]) do
      priority =
        case activity.data["type"] do
          "Delete" -> 10
          "Create" -> 1
          _ -> 5
        end

      Federator.enqueue(:publish, activity, priority)
    end

    :ok
  end

  def maybe_federate(_), do: :ok

  @doc """
  Applies to activities sent by group members from outside this instance to a group of this instance,
  we then need to relay (`Announce`) the object to other members on other instances.
  """
  def maybe_relay_if_group_activity(activity, attributed_to \\ nil)

  def maybe_relay_if_group_activity(
        %Activity{local: false, data: %{"object" => object}},
        _attributed_to
      )
      when is_map(object) do
    do_maybe_relay_if_group_activity(object, object["attributedTo"])
  end

  # When doing a delete the object is just an AP ID string, so we pass the attributed_to actor as well
  def maybe_relay_if_group_activity(
        %Activity{local: false, data: %{"object" => object}},
        %Actor{url: attributed_to_url}
      )
      when is_binary(object) do
    do_maybe_relay_if_group_activity(object, attributed_to_url)
  end

  def maybe_relay_if_group_activity(_, _), do: :ok

  defp do_maybe_relay_if_group_activity(object, attributed_to) when not is_nil(attributed_to) do
    id = "#{Endpoint.url()}/announces/#{Ecto.UUID.generate()}"

    case Actors.get_local_group_by_url(attributed_to) do
      %Actor{} = group ->
        case ActivityPub.announce(group, object, id, true, false) do
          {:ok, _activity, _object} ->
            Logger.info("Forwarded activity to external members of the group")
            :ok

          _ ->
            Logger.info("Failed to forward activity to external members of the group")
            :error
        end

      _ ->
        :ok
    end
  end

  defp do_maybe_relay_if_group_activity(_, _), do: :ok

  @spec remote_actors(list(String.t())) :: list(Actor.t())
  def remote_actors(recipients) do
    recipients
    |> Enum.map(fn url -> ActivityPub.get_or_fetch_actor_by_url(url) end)
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
  def lazy_put_activity_defaults(%{"object" => _object} = map) do
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
  def lazy_put_object_defaults(map) when is_map(map) do
    Map.put_new_lazy(map, "published", &make_date/0)
  end

  def get_actor(%{"actor" => actor}) when is_binary(actor) do
    actor
  end

  def get_actor(%{"actor" => actor}) when is_list(actor) do
    if is_binary(Enum.at(actor, 0)) do
      Enum.at(actor, 0)
    else
      actor
      |> Enum.find(fn %{"type" => type} -> type in ["Person", "Service", "Application"] end)
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
  Checks that an incoming AP object's actor matches the domain it came from.

  Takes the actor or attributedTo attributes (considers only the first elem if they're an array)
  """
  def origin_check?(id, %{"actor" => actor, "attributedTo" => _attributed_to} = params)
      when not is_nil(actor) and actor != "" do
    params = Map.delete(params, "attributedTo")
    origin_check?(id, params)
  end

  def origin_check?(id, %{"attributedTo" => actor} = params) do
    params = params |> Map.put("actor", actor) |> Map.delete("attributedTo")
    origin_check?(id, params)
  end

  def origin_check?(id, %{"actor" => actor} = params)
      when not is_nil(actor) and is_list(actor) and length(actor) > 0 do
    origin_check?(id, Map.put(params, "actor", hd(actor)))
  end

  def origin_check?(id, %{"actor" => actor} = params)
      when not is_nil(actor) do
    actor = get_actor(params)
    Logger.debug("Performing origin check on #{id} and #{actor} URIs")
    compare_origins?(id, actor)
  end

  def origin_check?(_id, %{"type" => type} = _params) when type in ["Actor", "Group"], do: true

  def origin_check?(_id, %{"actor" => nil} = _args), do: false

  def origin_check?(_id, _args), do: false

  @spec compare_origins?(String.t(), String.t()) :: boolean()
  def compare_origins?(url_1, url_2) when is_binary(url_1) and is_binary(url_2) do
    uri_1 = URI.parse(url_1)
    uri_2 = URI.parse(url_2)

    compare_uris?(uri_1, uri_2)
  end

  defp compare_uris?(%URI{} = id_uri, %URI{} = other_uri), do: id_uri.host == other_uri.host

  @spec origin_check_from_id?(String.t(), String.t()) :: boolean()
  def origin_check_from_id?(id, other_id) when is_binary(other_id) do
    id_uri = URI.parse(id)
    other_uri = URI.parse(other_id)

    compare_uris?(id_uri, other_uri)
  end

  @spec origin_check_from_id?(String.t(), map()) :: boolean()
  def origin_check_from_id?(id, %{"id" => other_id} = _params) when is_binary(other_id),
    do: origin_check_from_id?(id, other_id)

  def activity_actor_is_group_member?(%Actor{id: actor_id}, object) do
    case Ownable.group_actor(object) do
      %Actor{type: :Group, id: group_id} ->
        Actors.is_member?(actor_id, group_id)

      _ ->
        false
    end
  end

  @doc """
  Save picture data from %Plug.Upload{} and return AS Link data.
  """
  def make_picture_data(%Plug.Upload{} = picture, opts) do
    case Mobilizon.Web.Upload.store(picture, opts) do
      {:ok, picture} ->
        picture

      _ ->
        nil
    end
  end

  @doc """
  Convert a picture model into an AS Link representation.
  """
  def make_picture_data(%Picture{} = picture) do
    Converter.Picture.model_to_as(picture)
  end

  @doc """
  Save picture data from raw data and return AS Link data.
  """
  def make_picture_data(picture) when is_map(picture) do
    with {:ok, %{"url" => [%{"href" => url, "mediaType" => content_type}], "size" => size}} <-
           Mobilizon.Web.Upload.store(picture.file),
         {:picture_exists, nil} <- {:picture_exists, Mobilizon.Media.get_picture_by_url(url)},
         {:ok, %Picture{file: _file} = picture} <-
           Mobilizon.Media.create_picture(%{
             "file" => %{
               "url" => url,
               "name" => picture.name,
               "content_type" => content_type,
               "size" => size
             },
             "actor_id" => picture.actor_id
           }) do
      Converter.Picture.model_to_as(picture)
    else
      {:picture_exists, %Picture{file: _file} = picture} ->
        Converter.Picture.model_to_as(picture)

      err ->
        err
    end
  end

  def make_picture_data(nil), do: nil

  @doc """
  Make announce activity data for the given actor and object
  """
  def make_announce_data(actor, object, activity_id, public \\ true)

  def make_announce_data(
        %Actor{} = actor,
        %{"id" => url, "type" => type} = _object,
        activity_id,
        public
      )
      when type in @actor_types do
    do_make_announce_data(actor, url, url, activity_id, public)
  end

  def make_announce_data(
        %Actor{} = actor,
        %{"id" => url, "type" => type, "actor" => object_actor_url} = _object,
        activity_id,
        public
      )
      when type in ["Note", "Event", "ResourceCollection", "Document", "Todo"] do
    do_make_announce_data(
      actor,
      object_actor_url,
      url,
      activity_id,
      public
    )
  end

  defp do_make_announce_data(
         %Actor{type: actor_type} = actor,
         object_actor_url,
         object_url,
         activity_id,
         public
       ) do
    {to, cc} =
      if public do
        {[actor.followers_url, object_actor_url],
         ["https://www.w3.org/ns/activitystreams#Public"]}
      else
        if actor_type == :Group do
          {[actor.members_url], []}
        else
          {[actor.followers_url], []}
        end
      end

    data = %{
      "type" => "Announce",
      "actor" => actor.url,
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
  def make_create_data(object, additional \\ %{}) do
    Logger.debug("Making create data")
    Logger.debug(inspect(object))
    Logger.debug(inspect(additional))

    %{
      "type" => "Create",
      "to" => object["to"],
      "cc" => object["cc"],
      "attributedTo" => object["attributedTo"] || object["actor"],
      "actor" => object["actor"],
      "object" => object,
      "published" => make_date(),
      "id" => object["id"] <> "/activity"
    }
    |> Map.merge(additional)
  end

  @doc """
  Make update activity data
  """
  @spec make_update_data(map(), map()) :: map()
  def make_update_data(object, additional \\ %{}) do
    Logger.debug("Making update data")
    Logger.debug(inspect(object))
    Logger.debug(inspect(additional))

    %{
      "type" => "Update",
      "to" => object["to"],
      "cc" => object["cc"],
      "actor" => object["actor"],
      "object" => object,
      "id" => object["id"] <> "/activity"
    }
    |> Map.merge(additional)
  end

  @doc """
  Make accept join activity data
  """
  @spec make_accept_join_data(map(), map()) :: map()
  def make_accept_join_data(object, additional \\ %{}) do
    %{
      "type" => "Accept",
      "to" => object["to"],
      "cc" => object["cc"],
      "object" => object,
      "id" => object["id"] <> "/activity"
    }
    |> Map.merge(additional)
  end

  @doc """
  Make add activity data
  """
  @spec make_add_data(map(), map()) :: map()
  def make_add_data(object, target, additional \\ %{}) do
    Logger.debug("Making add data")
    Logger.debug(inspect(object))
    Logger.debug(inspect(additional))

    %{
      "type" => "Add",
      "to" => object["to"],
      "cc" => object["cc"],
      "actor" => object["actor"],
      "object" => object,
      "target" => Map.get(target, :url, target),
      "id" => object["id"] <> "/add"
    }
    |> Map.merge(additional)
  end

  @doc """
  Make move activity data
  """
  @spec make_add_data(map(), map()) :: map()
  def make_move_data(object, origin, target, additional \\ %{}) do
    Logger.debug("Making move data")
    Logger.debug(inspect(object))
    Logger.debug(inspect(origin))
    Logger.debug(inspect(target))
    Logger.debug(inspect(additional))

    %{
      "type" => "Move",
      "to" => object["to"],
      "cc" => object["cc"],
      "actor" => object["actor"],
      "object" => object,
      "origin" => if(is_nil(origin), do: origin, else: Map.get(origin, :url, origin)),
      "target" => if(is_nil(target), do: target, else: Map.get(target, :url, target)),
      "id" => object["id"] <> "/move"
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

  def pem_to_public_key_pem(pem) do
    public_key = pem_to_public_key(pem)
    public_key = :public_key.pem_entry_encode(:RSAPublicKey, public_key)
    :public_key.pem_encode([public_key])
  end

  def make_signature(actor, id, date) do
    uri = URI.parse(id)

    signature =
      actor
      |> HTTPSignatures.Signature.sign(%{
        "(request-target)": "get #{uri.path}",
        host: uri.host,
        date: date
      })

    [{:Signature, signature}]
  end

  @doc """
  Sign a request with the instance Relay actor.
  """
  @spec sign_fetch_relay(Enum.t(), String.t(), String.t()) :: Enum.t()
  def sign_fetch_relay(headers, id, date) do
    with %Actor{} = actor <- Relay.get_actor() do
      sign_fetch(headers, actor, id, date)
    end
  end

  @doc """
  Sign a request with an actor.
  """
  @spec sign_fetch(Enum.t(), Actor.t(), String.t(), String.t()) :: Enum.t()
  def sign_fetch(headers, actor, id, date) do
    if Mobilizon.Config.get([:activitypub, :sign_object_fetches]) do
      headers ++ make_signature(actor, id, date)
    else
      headers
    end
  end

  @doc """
  Add the Date header to the request if we sign object fetches
  """
  @spec maybe_date_fetch(Enum.t(), String.t()) :: Enum.t()
  def maybe_date_fetch(headers, date) do
    if Mobilizon.Config.get([:activitypub, :sign_object_fetches]) do
      headers ++ [{:Date, date}]
    else
      headers
    end
  end

  def check_for_actor_key_rotation(%Actor{} = actor) do
    if Actors.should_rotate_actor_key(actor) do
      Actors.schedule_key_rotation(
        actor,
        Application.get_env(:mobilizon, :activitypub)[:actor_key_rotation_delay]
      )
    end

    :ok
  end
end
