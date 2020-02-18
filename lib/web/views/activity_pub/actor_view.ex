defmodule Mobilizon.Web.ActivityPub.ActorView do
  use Mobilizon.Web, :view

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Resources
  alias Mobilizon.Resources.Resource

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
      "id" => actor.followers_url,
      "type" => "OrderedCollection",
      "totalItems" => total,
      "first" => collection(followers, actor.preferred_username, :followers, 1, total)
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("members.json", %{group: group, page: page, actor_applicant: actor_applicant}) do
    %{total: total, elements: members} =
      if Actor.is_public_visibility(group) ||
           actor_applicant_group_member?(group, actor_applicant),
         do: Actors.list_members_for_group(group, page),
         else: @private_visibility_empty_collection

    members
    |> collection(group.preferred_username, :members, page, total)
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("members.json", %{group: group, actor_applicant: actor_applicant}) do
    %{total: total, elements: members} =
      if Actor.is_public_visibility(group) ||
           actor_applicant_group_member?(group, actor_applicant),
         do: Actors.list_members_for_group(group),
         else: @private_visibility_empty_collection

    %{
      "id" => group.url,
      "attributedTo" => group.url,
      "type" => "OrderedCollection",
      "totalItems" => total,
      "first" => collection(members, group.preferred_username, :members, 1, total)
    }
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("resources.json", %{group: group, page: page, actor_applicant: actor_applicant}) do
    %{total: total, elements: resources} =
      if Actor.is_public_visibility(group) ||
           actor_applicant_group_member?(group, actor_applicant),
         do: Resources.get_top_level_resources_for_group(group),
         else: @private_visibility_empty_collection

    resources
    |> collection(group.preferred_username, :resources, page, total)
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("resources.json", %{group: group, actor_applicant: actor_applicant}) do
    %{total: total, elements: resources} =
      if Actor.is_public_visibility(group) ||
           actor_applicant_group_member?(group, actor_applicant),
         do: Resources.get_top_level_resources_for_group(group),
         else: @private_visibility_empty_collection

    %{
      "id" => group.resources_url,
      "attributedTo" => group.url,
      "type" => "OrderedCollection",
      "totalItems" => total,
      "first" => collection(resources, group.preferred_username, :resources, 1, total)
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
       when endpoint in [:followers, :following, :outbox, :members, :resources, :todos] do
    offset = (page - 1) * 10

    map = %{
      "id" => Actor.build_url(preferred_username, endpoint, page: page),
      "attributedTo" => Actor.build_url(preferred_username, :page),
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
  def item(%Member{} = member), do: Convertible.model_to_as(member)
  def item(%Resource{} = resource), do: Convertible.model_to_as(resource)

  defp actor_applicant_group_member?(%Actor{}, nil), do: false

  defp actor_applicant_group_member?(%Actor{id: group_id}, %Actor{id: actor_applicant_id}),
    do:
      Actors.get_member(actor_applicant_id, group_id, [
        :member,
        :moderator,
        :administrator,
        :creator
      ]) != {:error, :member_not_found}
end
