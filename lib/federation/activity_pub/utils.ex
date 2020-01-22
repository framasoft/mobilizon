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

  alias Mobilizon.Federation.ActivityPub.{Activity, Federator, Relay}
  alias Mobilizon.Federation.ActivityStream.Converter
  alias Mobilizon.Federation.HTTPSignatures

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
  """
  def origin_check?(id, %{"actor" => actor} = params) when not is_nil(actor) do
    id_uri = URI.parse(id)
    actor_uri = URI.parse(get_actor(params))

    compare_uris?(actor_uri, id_uri)
  end

  def origin_check?(_id, %{"actor" => nil}), do: false

  def origin_check?(id, %{"attributedTo" => actor} = params),
    do: origin_check?(id, Map.put(params, "actor", actor))

  def origin_check?(_id, _data), do: false

  defp compare_uris?(%URI{} = id_uri, %URI{} = other_uri), do: id_uri.host == other_uri.host

  def origin_check_from_id?(id, other_id) when is_binary(other_id) do
    id_uri = URI.parse(id)
    other_uri = URI.parse(other_id)

    compare_uris?(id_uri, other_uri)
  end

  def origin_check_from_id?(id, %{"id" => other_id} = _params) when is_binary(other_id),
    do: origin_check_from_id?(id, other_id)

  @doc """
  Save picture data from %Plug.Upload{} and return AS Link data.
  """
  def make_picture_data(%Plug.Upload{} = picture, opts) do
    case MobilizonWeb.Upload.store(picture, opts) do
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
           MobilizonWeb.Upload.store(picture.file),
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
  def make_create_data(object, additional \\ %{}) do
    Logger.debug("Making create data")
    Logger.debug(inspect(object))
    Logger.debug(inspect(additional))

    %{
      "type" => "Create",
      "to" => object["to"],
      "cc" => object["cc"],
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

  defp make_signature(id, date) do
    uri = URI.parse(id)

    signature =
      Relay.get_actor()
      |> HTTPSignatures.Signature.sign(%{
        "(request-target)": "get #{uri.path}",
        host: uri.host,
        date: date
      })

    [{:Signature, signature}]
  end

  def sign_fetch(headers, id, date) do
    if Mobilizon.Config.get([:activitypub, :sign_object_fetches]) do
      headers ++ make_signature(id, date)
    else
      headers
    end
  end

  def maybe_date_fetch(headers, date) do
    if Mobilizon.Config.get([:activitypub, :sign_object_fetches]) do
      headers ++ [{:Date, date}]
    else
      headers
    end
  end
end
