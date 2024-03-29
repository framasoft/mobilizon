defmodule Mobilizon.Federation.ActivityStream.Converter.Actor do
  @moduledoc """
  Actor converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor, as: ActorModel
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.ActivityStream.Converter.Address, as: AddressConverter
  alias Mobilizon.Medias.File
  alias Mobilizon.Service.HTTP.RemoteMediaDownloaderClient
  alias Mobilizon.Service.RichMedia.Parser
  alias Mobilizon.Web.Upload
  import Mobilizon.Federation.ActivityStream.Converter.Utils, only: [get_address: 1]
  import Mobilizon.Federation.ActivityPub.Utils, only: [create_full_domain_string: 1]

  @behaviour Converter

  defimpl Convertible, for: ActorModel do
    alias Mobilizon.Federation.ActivityStream.Converter.Actor, as: ActorConverter

    defdelegate model_to_as(actor), to: ActorConverter
  end

  @allowed_types ["Application", "Group", "Organization", "Person", "Service"]

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map()) :: map() | {:error, :actor_not_allowed_type}
  def as_to_model_data(%{"type" => type} = data) when type in @allowed_types do
    avatar =
      download_picture(
        get_picture(data, ["icon", "url"]),
        get_picture(data, ["icon", "name"]),
        "avatar"
      )

    banner =
      download_picture(
        get_picture(data, ["image", "url"]),
        get_picture(data, ["image", "name"]),
        "banner"
      )

    address = get_address(data["location"])

    %{
      url: data["id"],
      avatar: avatar,
      banner: banner,
      name: data["name"],
      preferred_username: data["preferredUsername"],
      summary: data["summary"] || "",
      keys: data["publicKey"]["publicKeyPem"],
      inbox_url: data["inbox"],
      outbox_url: data["outbox"],
      following_url: data["following"],
      followers_url: data["followers"],
      domain: data["id"] |> URI.new!() |> create_full_domain_string(),
      manually_approves_followers: data["manuallyApprovesFollowers"],
      type: data["type"],
      visibility: if(Map.get(data, "discoverable", false) == true, do: :public, else: :unlisted),
      openness: data["openness"],
      physical_address_id: if(address, do: address.id, else: nil)
    }
    |> add_endpoints_to_model(data)
  end

  def as_to_model_data(_), do: {:error, :actor_not_allowed_type}

  defp add_endpoints_to_model(actor, data) do
    endpoints = %{
      members_url: get_in(data, ["endpoints", "members"]),
      resources_url: get_in(data, ["endpoints", "resources"]),
      todos_url: get_in(data, ["endpoints", "todos"]),
      events_url: get_in(data, ["endpoints", "events"]),
      posts_url: get_in(data, ["endpoints", "posts"]),
      discussions_url: get_in(data, ["endpoints", "discussions"]),
      shared_inbox_url: data["endpoints"]["sharedInbox"]
    }

    Map.merge(actor, endpoints)
  end

  @doc """
  Convert an actor struct to an ActivityStream representation.
  """
  @impl Converter
  @spec model_to_as(ActorModel.t()) :: map()
  def model_to_as(%ActorModel{} = actor) do
    actor_data = %{
      "id" => actor.url,
      "type" => actor.type,
      "preferredUsername" => actor.preferred_username,
      "name" => actor.name,
      "summary" => actor.summary || "",
      "following" => actor.following_url,
      "followers" => actor.followers_url,
      "inbox" => actor.inbox_url,
      "outbox" => actor.outbox_url,
      "url" => actor.url,
      "endpoints" => %{
        "sharedInbox" => actor.shared_inbox_url
      },
      "discoverable" => actor.visibility == :public,
      "openness" => actor.openness,
      "manuallyApprovesFollowers" => actor.manually_approves_followers
    }

    actor_data
    |> add_keys(actor)
    |> add_endpoints(actor)
    |> maybe_add_members(actor)
    |> maybe_add_avatar_picture(actor)
    |> maybe_add_banner_picture(actor)
    |> maybe_add_physical_address(actor)
  end

  @spec add_keys(map(), ActorModel.t()) :: map()
  defp add_keys(actor_data, %ActorModel{} = actor) do
    keys =
      if is_nil(actor.domain) and not is_nil(actor.keys) do
        case Utils.pem_to_public_key_pem(actor.keys) do
          {:error, :no_publickey_found} ->
            raise "No publickey found in private keys"

          public_key when is_binary(public_key) ->
            public_key
        end
      else
        actor.keys
      end

    Map.put(actor_data, "publicKey", %{
      "id" => "#{actor.url}#main-key",
      "owner" => actor.url,
      "publicKeyPem" => keys
    })
  end

  defp add_endpoints(%{"endpoints" => endpoints} = actor_data, %ActorModel{} = actor) do
    new_endpoints = %{
      "members" => actor.members_url,
      "resources" => actor.resources_url,
      "todos" => actor.todos_url,
      "posts" => actor.posts_url,
      "events" => actor.events_url,
      "discussions" => actor.discussions_url
    }

    endpoints = Map.merge(endpoints, new_endpoints)

    actor_data
    |> Map.merge(new_endpoints)
    |> Map.put("endpoints", endpoints)
  end

  @spec download_picture(String.t() | nil, String.t(), String.t()) :: map() | nil
  defp download_picture(nil, _name, _default_name), do: nil

  defp download_picture(url, name, default_name) do
    with {:ok, %{body: body, status: code, headers: response_headers}}
         when code in 200..299 <- RemoteMediaDownloaderClient.get(url),
         name <- name || Parser.get_filename_from_response(response_headers, url) || default_name,
         {:ok, file} <- Upload.store(%{body: body, name: name}) do
      Map.take(file, [:content_type, :name, :url, :size])
    else
      _ -> nil
    end
  end

  defp maybe_add_members(actor_data, %ActorModel{type: :Group, members_url: members_url} = group) do
    actor_data
    |> Map.put("members", members_url)
    |> Map.put("memberCount", Actors.count_members_for_group(group))
  end

  defp maybe_add_members(actor_data, %ActorModel{}), do: actor_data

  @spec maybe_add_avatar_picture(map(), ActorModel.t()) :: map()
  defp maybe_add_avatar_picture(actor_data, %ActorModel{avatar: %File{} = avatar}) do
    Map.put(actor_data, "icon", %{
      "type" => "Image",
      "mediaType" => avatar.content_type,
      "url" => avatar.url
    })
  end

  defp maybe_add_avatar_picture(res, %ActorModel{avatar: _}), do: res

  @spec maybe_add_banner_picture(map(), ActorModel.t()) :: map()
  defp maybe_add_banner_picture(actor_data, %ActorModel{banner: %File{} = banner}) do
    Map.put(actor_data, "image", %{
      "type" => "Image",
      "mediaType" => banner.content_type,
      "url" => banner.url
    })
  end

  defp maybe_add_banner_picture(res, %ActorModel{banner: _}), do: res

  @spec maybe_add_physical_address(map(), ActorModel.t()) :: map()
  defp maybe_add_physical_address(res, %ActorModel{
         physical_address: %Address{} = physical_address
       }) do
    Map.put(res, "location", AddressConverter.model_to_as(physical_address))
  end

  defp maybe_add_physical_address(res, _), do: res

  defp get_picture(nil, _keys), do: nil
  defp get_picture(url, _keys) when is_binary(url), do: url

  defp get_picture(data, [key | rest] = keys) when is_map(data) and is_list(keys),
    do: get_picture(data[key], rest)
end
