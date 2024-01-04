defmodule Mobilizon.GraphQL.Resolvers.Member do
  @moduledoc """
  Handles the member-related GraphQL calls
  """

  import Mobilizon.Users.Guards
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  @doc """
  Find members for group.

  If actor requesting is not part of the group, we only return the number of members, not members
  """
  @spec find_members_for_group(Actor.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Member.t())}
  def find_members_for_group(
        %Actor{id: group_id} = group,
        %{page: page, limit: limit, roles: roles} = args,
        %{
          context: %{current_user: %User{role: user_role}, current_actor: %Actor{id: actor_id}}
        } = _resolution
      ) do
    if Actors.member?(actor_id, group_id) or is_moderator(user_role) do
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

      %Page{} =
        page = Actors.list_members_for_group(group, Map.get(args, :name), roles, page, limit)

      {:ok, page}
    else
      # Actor is not member of group, fallback to public
      %Page{} = page = Actors.list_members_for_group(group)
      {:ok, %Page{page | elements: []}}
    end
  end

  def find_members_for_group(%Actor{} = group, _args, _resolution) do
    %Page{} = page = Actors.list_members_for_group(group)
    {:ok, %Page{page | elements: []}}
  end

  @spec invite_member(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Member.t()} | {:error, String.t()}
  def invite_member(
        _parent,
        %{group_id: group_id, target_actor_username: target_actor_username},
        %{context: %{current_actor: %Actor{id: actor_id} = actor}}
      ) do
    with {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         {:has_rights_to_invite, {:ok, %Member{role: role}}}
         when role in [:moderator, :administrator, :creator] <-
           {:has_rights_to_invite, Actors.get_member(actor_id, group_id)},
         target_actor_username <-
           target_actor_username |> String.trim() |> String.trim_leading("@"),
         {:target_actor_username, {:ok, %Actor{id: target_actor_id} = target_actor}} <-
           {:target_actor_username,
            ActivityPubActor.find_or_make_actor_from_nickname(target_actor_username)},
         {:existant, true} <-
           {:existant, check_member_not_existant_or_rejected(target_actor_id, group.id)},
         {:ok, _activity, %Member{} = member} <-
           Actions.Invite.invite(group, actor, target_actor) do
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

  @spec accept_invitation(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Member.t()} | {:error, String.t()}
  def accept_invitation(_parent, %{id: member_id}, %{
        context: %{current_actor: %Actor{id: actor_id}}
      }) do
    with %Member{actor: %Actor{id: member_actor_id}} = member <-
           Actors.get_member(member_id),
         {:is_same_actor, true} <- {:is_same_actor, member_actor_id == actor_id},
         {:ok, _activity, %Member{} = member} <-
           Actions.Accept.accept(
             :invite,
             member,
             true
           ) do
      {:ok, member}
    else
      {:is_same_actor, false} ->
        {:error, dgettext("errors", "You can't accept this invitation with this profile.")}
    end
  end

  @spec reject_invitation(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Member.t()} | {:error, String.t()}
  def reject_invitation(_parent, %{id: member_id}, %{
        context: %{current_actor: %Actor{id: actor_id}}
      }) do
    with {:invitation_exists, %Member{actor: %Actor{id: member_actor_id}} = member} <-
           {:invitation_exists, Actors.get_member(member_id)},
         {:is_same_actor, true} <- {:is_same_actor, member_actor_id == actor_id},
         {:ok, _activity, %Member{} = member} <-
           Actions.Reject.reject(
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

  def approve_member(_parent, %{member_id: member_id}, %{
        context: %{current_actor: %Actor{} = moderator}
      }) do
    case Actors.get_member(member_id) do
      %Member{} = member ->
        with {:ok, _activity, %Member{} = member} <-
               Actions.Accept.accept(:member, member, true, %{moderator: moderator}) do
          {:ok, member}
        end

      {:error, :member_not_found} ->
        {:error, dgettext("errors", "You are not a moderator or admin for this group")}
    end
  end

  # TODO : Maybe remove me ? Remove member with exclude parameter does the same
  def reject_member(_parent, %{member_id: member_id}, %{
        context: %{current_actor: %Actor{} = moderator}
      }) do
    case Actors.get_member(member_id) do
      %Member{} = member ->
        with {:ok, _activity, %Member{} = member} <-
               Actions.Reject.reject(:member, member, true, %{moderator: moderator}) do
          {:ok, member}
        end

      {:error, :member_not_found} ->
        {:error, dgettext("errors", "You are not a moderator or admin for this group")}
    end
  end

  @spec update_member(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Member.t()} | {:error, String.t()}
  def update_member(_parent, %{member_id: member_id, role: role}, %{
        context: %{current_actor: %Actor{} = moderator}
      }) do
    with %Member{} = member <- Actors.get_member(member_id),
         {:ok, _activity, %Member{} = member} <-
           Actions.Update.update(member, %{role: role}, true, %{moderator: moderator}) do
      {:ok, member}
    else
      {:error, :member_not_found} ->
        {:error, dgettext("errors", "You are not a moderator or admin for this group")}

      {:error, :only_admin_left} ->
        {:error,
         dgettext(
           "errors",
           "You can't set yourself to a lower member role for this group because you are the only administrator"
         )}
    end
  end

  def update_member(_parent, _args, _resolution),
    do: {:error, "You must be logged-in to update a member"}

  @spec remove_member(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Member.t()} | {:error, String.t()}
  def remove_member(_parent, %{member_id: member_id, exclude: _exclude}, %{
        context: %{current_actor: %Actor{id: moderator_id} = moderator}
      }) do
    case Actors.get_member(member_id) do
      nil ->
        {:error,
         dgettext(
           "errors",
           "This member does not exist"
         )}

      %Member{role: :rejected} ->
        {:error,
         dgettext(
           "errors",
           "This member already has been rejected."
         )}

      %Member{parent_id: group_id} = member ->
        case Actors.get_member(moderator_id, group_id) do
          {:ok, %Member{role: role}} when role in [:moderator, :administrator, :creator] ->
            %Actor{type: :Group} = group = Actors.get_actor(group_id)

            with {:ok, _activity, %Member{}} <-
                   Actions.Remove.remove(member, group, moderator, true) do
              {:ok, member}
            end

          {:ok, %Member{}} ->
            {:error,
             dgettext(
               "errors",
               "You don't have the role needed to remove this member."
             )}

          {:error, :member_not_found} ->
            {:error,
             dgettext(
               "errors",
               "You don't have the right to remove this member."
             )}
        end
    end
  end

  def remove_member(_parent, _args, _resolution),
    do:
      {:error,
       dgettext(
         "errors",
         "You must be logged-in to remove a member"
       )}

  def count_members_for_group(%Actor{type: :Group} = group, _args, _resolution) do
    {:ok, Actors.count_members_for_group(group)}
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
