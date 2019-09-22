defmodule MobilizonWeb.ActivityPub.ActorView do
  use MobilizonWeb, :view

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.{Activity, Utils}

  @private_visibility_empty_collection %{elements: [], total: 0}

  def render("actor.json", %{actor: actor}) do
    public_key = Mobilizon.Service.ActivityPub.Utils.pem_to_public_key_pem(actor.keys)

    %{
      "id" => actor.url,
      "type" => to_string(actor.type),
      "following" => actor.following_url,
      "followers" => actor.followers_url,
      "inbox" => actor.inbox_url,
      "outbox" => actor.outbox_url,
      "preferredUsername" => actor.preferred_username,
      "name" => actor.name,
      "summary" => actor.summary,
      "url" => actor.url,
      "manuallyApprovesFollowers" => actor.manually_approves_followers,
      "publicKey" => %{
        "id" => "#{actor.url}#main-key",
        "owner" => actor.url,
        "publicKeyPem" => public_key
      },
      # TODO : Make have actors have an uuid
      # "uuid" => actor.uuid
      "endpoints" => %{
        "sharedInbox" => actor.shared_inbox_url
      }
      #      "icon" => %{
      #        "type" => "Image",
      #        "url" => User.avatar_url(actor)
      #      },
      #      "image" => %{
      #        "type" => "Image",
      #        "url" => User.banner_url(actor)
      #      }
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("following.json", %{actor: actor, page: page}) do
    %{total: total, elements: following} =
      if Actor.is_public_visibility(actor),
        do: Actors.build_followings_for_actor(actor, page),
        else: @private_visibility_empty_collection

    following
    |> collection(actor.preferred_username, :following, page, total)
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("following.json", %{actor: actor}) do
    %{total: total, elements: following} =
      if Actor.is_public_visibility(actor),
        do: Actors.build_followings_for_actor(actor),
        else: @private_visibility_empty_collection

    %{
      "id" => Actor.build_url(actor.preferred_username, :following),
      "type" => "OrderedCollection",
      "totalItems" => total,
      "first" => collection(following, actor.preferred_username, :following, 1, total)
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("followers.json", %{actor: actor, page: page}) do
    %{total: total, elements: followers} =
      if Actor.is_public_visibility(actor),
        do: Actors.build_followers_for_actor(actor, page),
        else: @private_visibility_empty_collection

    followers
    |> collection(actor.preferred_username, :followers, page, total)
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("followers.json", %{actor: actor}) do
    %{total: total, elements: followers} =
      if Actor.is_public_visibility(actor),
        do: Actors.build_followers_for_actor(actor),
        else: @private_visibility_empty_collection

    %{
      "id" => Actor.build_url(actor.preferred_username, :followers),
      "type" => "OrderedCollection",
      "totalItems" => total,
      "first" => collection(followers, actor.preferred_username, :followers, 1, total)
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("outbox.json", %{actor: actor, page: page}) do
    %{total: total, elements: followers} =
      if Actor.is_public_visibility(actor),
        do: ActivityPub.fetch_public_activities_for_actor(actor, page),
        else: @private_visibility_empty_collection

    followers
    |> collection(actor.preferred_username, :outbox, page, total)
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("outbox.json", %{actor: actor}) do
    %{total: total, elements: followers} =
      if Actor.is_public_visibility(actor),
        do: ActivityPub.fetch_public_activities_for_actor(actor),
        else: @private_visibility_empty_collection

    %{
      "id" => Actor.build_url(actor.preferred_username, :outbox),
      "type" => "OrderedCollection",
      "totalItems" => total,
      "first" => collection(followers, actor.preferred_username, :outbox, 1, total)
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  @spec collection(list(), String.t(), atom(), integer(), integer()) :: map()
  defp collection(collection, preferred_username, endpoint, page, total)
       when endpoint in [:followers, :following, :outbox] do
    offset = (page - 1) * 10

    map = %{
      "id" => Actor.build_url(preferred_username, endpoint, page: page),
      "type" => "OrderedCollectionPage",
      "partOf" => Actor.build_url(preferred_username, endpoint),
      "orderedItems" => Enum.map(collection, &item/1)
    }

    if offset < total do
      Map.put(map, "next", Actor.build_url(preferred_username, endpoint, page: page + 1))
    end

    map
  end

  def item(%Activity{data: %{"id" => id}}), do: id
  def item(%Actor{url: url}), do: url
end
