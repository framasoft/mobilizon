defmodule Mobilizon.Federation.ActivityStream.Converter.Actor do
  @moduledoc """
  Actor converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor, as: ActorModel

  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}

  alias Mobilizon.Web.MediaProxy

  @behaviour Converter

  defimpl Convertible, for: ActorModel do
    alias Mobilizon.Federation.ActivityStream.Converter.Actor, as: ActorConverter

    defdelegate model_to_as(actor), to: ActorConverter
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: map
  def as_to_model_data(data) do
    avatar =
      data["icon"]["url"] &&
        %{
          "name" => data["icon"]["name"] || "avatar",
          "url" => MediaProxy.url(data["icon"]["url"])
        }

    banner =
      data["image"]["url"] &&
        %{
          "name" => data["image"]["name"] || "banner",
          "url" => MediaProxy.url(data["image"]["url"])
        }

    actor_data = %{
      url: data["id"],
      avatar: avatar,
      banner: banner,
      name: data["name"],
      preferred_username: data["preferredUsername"],
      summary: data["summary"],
      keys: data["publicKey"]["publicKeyPem"],
      inbox_url: data["inbox"],
      outbox_url: data["outbox"],
      following_url: data["following"],
      followers_url: data["followers"],
      shared_inbox_url: data["endpoints"]["sharedInbox"],
      domain: URI.parse(data["id"]).host,
      manually_approves_followers: data["manuallyApprovesFollowers"],
      type: data["type"]
    }

    {:ok, actor_data}
  end

  @doc """
  Convert an actor struct to an ActivityStream representation.
  """
  @impl Converter
  @spec model_to_as(ActorModel.t()) :: map
  def model_to_as(%ActorModel{} = actor) do
    actor_data = %{
      "id" => actor.url,
      "type" => actor.type,
      "preferredUsername" => actor.preferred_username,
      "name" => actor.name,
      "summary" => actor.summary,
      "following" => actor.following_url,
      "followers" => actor.followers_url,
      "inbox" => actor.inbox_url,
      "outbox" => actor.outbox_url,
      "url" => actor.url,
      "endpoints" => %{
        "sharedInbox" => actor.shared_inbox_url
      },
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
end
