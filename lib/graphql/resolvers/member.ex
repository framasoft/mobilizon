defmodule Mobilizon.GraphQL.Resolvers.Member do
  @moduledoc """
  Handles the member-related GraphQL calls
  """

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  @doc """
  Find members for group.

  If actor requesting is not part of the group, we only return the number of members, not members
  """
  def find_members_for_group(
        %Actor{id: group_id} = group,
        %{page: page, limit: limit, roles: roles},
        %{
          context: %{current_user: %User{} = user}
        } = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)} do
      roles =
        case roles do
          "" ->
            []

          roles ->
            roles
            |> String.split(",")
            |> Enum.map(&String.downcase/1)
            |> Enum.map(&String.to_existing_atom/1)
        end

      %Page{} = page = Actors.list_members_for_group(group, roles, page, limit)
      {:ok, page}
    else
      {:member, false} ->
        # Actor is not member of group, fallback to public
        with %Page{} = page <- Actors.list_members_for_group(group) do
          {:ok, %Page{page | elements: []}}
        end
    end
  end

  def find_members_for_group(%Actor{} = group, _args, _resolution) do
    with %Page{} = page <- Actors.list_members_for_group(group) do
      {:ok, %Page{page | elements: []}}
    end
  end

  def invite_member(
        _parent,
        %{group_id: group_id, target_actor_username: target_actor_username},
        %{context: %{current_user: %User{} = user}}
      ) do
    with %Actor{id: actor_id} = actor <- Users.get_actor_for_user(user),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         {:has_rights_to_invite, {:ok, %Member{role: role}}}
         when role in [:moderator, :administrator, :creator] <-
           {:has_rights_to_invite, Actors.get_member(actor_id, group_id)},
         {:target_actor_username, {:ok, %Actor{id: target_actor_id} = target_actor}} <-
           {:target_actor_username,
            ActivityPub.find_or_make_actor_from_nickname(target_actor_username)},
         {:error, :member_not_found} <- Actors.get_member(target_actor_id, group.id),
         {:ok, _activity, %Member{} = member} <- ActivityPub.invite(group, actor, target_actor) do
      {:ok, member}
    else
      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}

      {:error, :group_not_found} ->
        {:error, "Group id not found"}

      {:target_actor_username, _} ->
        {:error, "Actor invited doesn't exist"}

      {:has_rights_to_invite, {:error, :member_not_found}} ->
        {:error, "You are not a member of this group"}

      {:has_rights_to_invite, _} ->
        {:error, "You cannot invite to this group"}

      {:ok, %Member{}} ->
        {:error, "Actor is already a member of this group"}
    end
  end

  def accept_invitation(_parent, %{id: member_id}, %{context: %{current_user: %User{} = user}}) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         %Member{actor: %Actor{id: member_actor_id}} = member <- Actors.get_member(member_id),
         {:is_same_actor, true} <- {:is_same_actor, member_actor_id === actor_id},
         {:ok, _activity, %Member{} = member} <-
           ActivityPub.accept(
             :invite,
             member,
             true
           ) do
      # Launch an async task to refresh the group profile, fetch resources, discussions, members
      {:ok, member}
    end
  end
end
