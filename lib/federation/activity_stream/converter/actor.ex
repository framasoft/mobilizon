defmodule Mobilizon.Federation.ActivityStream.Converter.Actor do
  @moduledoc """
  Actor converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor, as: ActorModel

  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}

  alias Mobilizon.Service.HTTP.RemoteMediaDownloaderClient
  alias Mobilizon.Service.RichMedia.Parser
  alias Mobilizon.Web.Upload

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
  @spec as_to_model_data(map()) :: {:ok, map()}
  def as_to_model_data(%{"type" => type} = data) when type in @allowed_types do
    avatar =
      download_picture(get_in(data, ["icon", "url"]), get_in(data, ["icon", "name"]), "avatar")

    banner =
      download_picture(get_in(data, ["image", "url"]), get_in(data, ["image", "name"]), "banner")

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
      members_url: data["members"],
      resources_url: data["resources"],
      todos_url: data["todos"],
      events_url: data["events"],
      posts_url: data["posts"],
      discussions_url: data["discussions"],
      shared_inbox_url: data["endpoints"]["sharedInbox"],
      domain: URI.parse(data["id"]).host,
      manually_approves_followers: data["manuallyApprovesFollowers"],
      type: data["type"],
      visibility: if(Map.get(data, "discoverable", false) == true, do: :public, else: :unlisted),
      openness: data["openness"]
    }
  end

  def as_to_model_data(_), do: :error

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
      "members" => actor.members_url,
      "resources" => actor.resources_url,
      "todos" => actor.todos_url,
      "posts" => actor.posts_url,
      "events" => actor.events_url,
      "discussions" => actor.discussions_url,
      "inbox" => actor.inbox_url,
      "outbox" => actor.outbox_url,
      "url" => actor.url,
      "endpoints" => %{
        "sharedInbox" => actor.shared_inbox_url
      },
      "discoverable" => actor.visibility == :public,
      "openness" => actor.openness,
      "manuallyApprovesFollowers" => actor.manually_approves_followers,
      "publicKey" => %{
        "id" => "#{actor.url}#main-key",
        "owner" => actor.url,
        "publicKeyPem" =>
          if(is_nil(actor.domain) and not is_nil(actor.keys),
            do: Utils.pem_to_public_key_pem(actor.keys),
            else: actor.keys
          )
      }
    }

    actor_data =
      if actor.type == :Group do
        Map.put(actor_data, "members", actor.members_url)
      else
        actor_data
      end

    actor_data =
      if is_nil(actor.avatar) do
        actor_data
      else
        Map.put(actor_data, "icon", %{
          "type" => "Image",
          "mediaType" => actor.avatar.content_type,
          "url" => actor.avatar.url
        })
      end

    if is_nil(actor.banner) do
      actor_data
    else
      Map.put(actor_data, "image", %{
        "type" => "Image",
        "mediaType" => actor.banner.content_type,
        "url" => actor.banner.url
      })
    end
  end

  @spec download_picture(String.t() | nil, String.t(), String.t()) :: map()
  defp download_picture(nil, _name, _default_name), do: nil

  defp download_picture(url, name, default_name) do
    with {:ok, %{body: body, status: code, headers: response_headers}}
         when code in 200..299 <- RemoteMediaDownloaderClient.get(url),
         name <- name || Parser.get_filename_from_response(response_headers, url) || default_name,
         {:ok, file} <- Upload.store(%{body: body, name: name}) do
      file
    end
  end
end
