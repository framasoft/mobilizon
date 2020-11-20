defmodule Mobilizon.GraphQL.Resolvers.Member do
  @moduledoc """
  Handles the member-related GraphQL calls
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Refresher
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  @doc """
  Find members for group.

  If actor requesting is not part of the group, we only return the number of members, not members
  """
  def find_members_for_group(
        %Actor{id: group_id} = group,
        %{page: page, limit: limit, roles: roles},
        %{
          context: %{current_user: %User{role: user_role} = user}
        } = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <-
           {:member, Actors.is_member?(actor_id, group_id) or is_moderator(user_role)} do
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
         target_actor_username <-
           target_actor_username |> String.trim() |> String.trim_leading("@"),
         {:target_actor_username, {:ok, %Actor{id: target_actor_id} = target_actor}} <-
           {:target_actor_username,
            ActivityPub.find_or_make_actor_from_nickname(target_actor_username)},
         {:existant, true} <-
           {:existant, check_member_not_existant_or_rejected(target_actor_id, group.id)},
         {:ok, _activity, %Member{} = member} <- ActivityPub.invite(group, actor, target_actor) do
      {:ok, member}
    else
      {:error, :group_not_found} ->
        {:error, dgettext("errors", "Group not found")}

      {:target_actor_username, _} ->
        {:error, dgettext("errors", "Profile invited doesn't exist")}

      {:has_rights_to_invite, {:error, :member_not_found}} ->
        {:error, dgettext("errors", "You are not a member of this group")}

      {:has_rights_to_invite, _} ->
        {:error, dgettext("errors", "You cannot invite to this group")}

      {:existant, _} ->
        {:error, dgettext("errors", "Profile is already a member of this group")}

      # Remove me ?
      {:ok, %Member{}} ->
        {:error, dgettext("errors", "Profile is already a member of this group")}
    end
  end

  def accept_invitation(_parent, %{id: member_id}, %{context: %{current_user: %User{} = user}}) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         %Member{actor: %Actor{id: member_actor_id} = actor} = member <-
           Actors.get_member(member_id),
         {:is_same_actor, true} <- {:is_same_actor, member_actor_id === actor_id},
         {:ok, _activity, %Member{} = member} <-
           ActivityPub.accept(
             :invite,
             member,
             true
           ) do
      # Launch an async task to refresh the group profile, fetch resources, discussions, members
      Refresher.fetch_group(member.parent.url, actor)
      {:ok, member}
    else
      {:is_same_actor, false} ->
        {:error, dgettext("errors", "You can't accept this invitation with this profile.")}
    end
  end

  def reject_invitation(_parent, %{id: member_id}, %{context: %{current_user: %User{} = user}}) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:invitation_exists, %Member{actor: %Actor{id: member_actor_id}} = member} <-
           {:invitation_exists, Actors.get_member(member_id)},
         {:is_same_actor, true} <- {:is_same_actor, member_actor_id === actor_id},
         {:ok, _activity, %Member{} = member} <-
           ActivityPub.reject(
             :invite,
             member,
             true
           ) do
      {:ok, member}
    else
      {:is_same_actor, false} ->
        {:error, dgettext("errors", "You can't reject this invitation with this profile.")}

      {:invitation_exists, _} ->
        {:error, dgettext("errors", "This invitation doesn't exist.")}
    end
  end

  def update_member(_parent, %{member_id: member_id, role: role}, %{
        context: %{current_user: %User{} = user}
      }) do
    with %Actor{} = moderator <- Users.get_actor_for_user(user),
         %Member{} = member <- Actors.get_member(member_id),
         {:ok, _activity, %Member{} = member} <-
           ActivityPub.update(member, %{role: role}, true, %{moderator: moderator}) do
      {:ok, member}
    else
      {:has_rights_to_update_role, {:error, :member_not_found}} ->
        {:error, dgettext("errors", "You are not a moderator or admin for this group")}

      {:is_only_admin, true} ->
        {:error,
         dgettext(
           "errors",
           "You can't set yourself to a lower member role for this group because you are the only administrator"
         )}
    end
  end

  def update_member(_parent, _args, _resolution),
    do: {:error, "You must be logged-in to update a member"}

  def remove_member(_parent, %{member_id: member_id, group_id: group_id}, %{
        context: %{current_user: %User{} = user}
      }) do
    with %Actor{id: moderator_id} = moderator <- Users.get_actor_for_user(user),
         %Member{role: role} = member when role != :rejected <- Actors.get_member(member_id),
         %Actor{type: :Group} = group <- Actors.get_actor(group_id),
         {:has_rights_to_remove, {:ok, %Member{role: role}}}
         when role in [:moderator, :administrator, :creator] <-
           {:has_rights_to_remove, Actors.get_member(moderator_id, group_id)},
         {:ok, _activity, %Member{}} <- ActivityPub.remove(member, group, moderator, true) do
      {:ok, member}
    else
      %Member{role: :rejected} ->
        {:error,
         dgettext(
           "errors",
           "This member already has been rejected."
         )}

      {:has_rights_to_remove, _} ->
        {:error,
         dgettext(
           "errors",
           "You don't have the right to remove this member."
         )}
    end
  end

  # Rejected members can be invited again
  @spec check_member_not_existant_or_rejected(String.t() | integer, String.t() | integer()) ::
          boolean()
  defp check_member_not_existant_or_rejected(target_actor_id, group_id) do
    case Actors.get_member(target_actor_id, group_id) do
      {:ok, %Member{role: :rejected}} ->
        true

      {:error, :member_not_found} ->
        true

      _err ->
        false
    end
  end
end
