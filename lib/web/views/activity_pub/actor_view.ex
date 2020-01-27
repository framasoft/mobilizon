defmodule Mobilizon.Web.ActivityPub.ActorView do
  use Mobilizon.Web, :view

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Activity, Utils}
  alias Mobilizon.Federation.ActivityStream.Convertible

  @private_visibility_empty_collection %{elements: [], total: 0}

  def render("actor.json", %{actor: actor}) do
    actor
    |> Convertible.model_to_as()
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
