defmodule Mobilizon.GraphQL.Resolvers.Group do
  @moduledoc """
  Handles the group-related GraphQL calls.
  """

  alias Mobilizon.{Actors, Events, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.GraphQL.API
  alias Mobilizon.GraphQL.Resolvers.Person
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  require Logger

  @doc """
  Find a group
  """
  def find_group(
        parent,
        %{preferred_username: name} = args,
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:ok, %Actor{id: group_id} = group} <-
           ActivityPub.find_or_make_group_from_nickname(name),
         {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         group <- Person.proxify_pictures(group) do
      {:ok, group}
    else
      {:member, false} ->
        find_group(parent, args, nil)

      _ ->
        {:error, "Group with name #{name} not found"}
    end
  end

  @doc """
  Find a group
  """
  def find_group(_parent, %{preferred_username: name}, _resolution) do
    with {:ok, actor} <- ActivityPub.find_or_make_group_from_nickname(name),
         %Actor{} = actor <- Person.proxify_pictures(actor),
         %Actor{} = actor <- restrict_fields_for_non_member_request(actor) do
      {:ok, actor}
    else
      _ ->
        {:error, "Group with name #{name} not found"}
    end
  end

  @doc """
  Lists all groups
  """
  def list_groups(_parent, %{page: page, limit: limit}, _resolution) do
    {:ok, Actors.list_groups(page, limit)}
  end

  @doc """
  Create a new group. The creator is automatically added as admin
  """
  def create_group(
        _parent,
        args,
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    with creator_actor_id <- Map.get(args, :creator_actor_id),
         {:is_owned, %Actor{} = creator_actor} <- User.owns_actor(user, creator_actor_id),
         args <- Map.put(args, :creator_actor, creator_actor),
         {:ok, _activity, %Actor{type: :Group} = group} <-
           API.Groups.create_group(args) do
      {:ok, group}
    else
      {:error, err} when is_bitstring(err) ->
        {:error, err}

      {:is_owned, nil} ->
        {:error, "Creator actor id is not owned by the current user"}
    end
  end

  def create_group(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create a group"}
  end

  @doc """
  Delete an existing group
  """
  def delete_group(
        _parent,
        %{group_id: group_id, actor_id: actor_id},
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    with {actor_id, ""} <- Integer.parse(actor_id),
         {group_id, ""} <- Integer.parse(group_id),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         {:is_owned, %Actor{}} <- User.owns_actor(user, actor_id),
         {:ok, %Member{} = member} <- Actors.get_member(actor_id, group.id),
         {:is_admin, true} <- {:is_admin, Member.is_administrator(member)},
         group <- Actors.delete_group!(group) do
      {:ok, %{id: group.id}}
    else
      {:error, :group_not_found} ->
        {:error, "Group not found"}

      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}

      {:error, :member_not_found} ->
        {:error, "Actor id is not a member of this group"}

      {:is_admin, false} ->
        {:error, "Actor id is not an administrator of the selected group"}
    end
  end

  def delete_group(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to delete a group"}
  end

  @doc """
  Join an existing group
  """
  def join_group(
        _parent,
        %{group_id: group_id, actor_id: actor_id},
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    with {actor_id, ""} <- Integer.parse(actor_id),
         {group_id, ""} <- Integer.parse(group_id),
         {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         {:error, :member_not_found} <- Actors.get_member(actor.id, group.id),
         {:is_able_to_join, true} <- {:is_able_to_join, Member.can_be_joined(group)},
         role <- Member.get_default_member_role(group),
         {:ok, _} <- Actors.create_member(%{parent_id: group.id, actor_id: actor.id, role: role}) do
      {
        :ok,
        %{
          parent: Person.proxify_pictures(group),
          actor: Person.proxify_pictures(actor),
          role: role
        }
      }
    else
      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}

      {:error, :group_not_found} ->
        {:error, "Group id not found"}

      {:is_able_to_join, false} ->
        {:error, "You cannot join this group"}

      {:ok, %Member{}} ->
        {:error, "You are already a member of this group"}
    end
  end

  def join_group(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to join a group"}
  end

  @doc """
  Leave a existing group
  """
  def leave_group(
        _parent,
        %{group_id: group_id, actor_id: actor_id},
        %{
          context: %{
            current_user: user
          }
        }
      ) do
    with {actor_id, ""} <- Integer.parse(actor_id),
         {group_id, ""} <- Integer.parse(group_id),
         {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
         {:ok, %Member{} = member} <- Actors.get_member(actor.id, group_id),
         {:only_administrator, false} <-
           {:only_administrator, check_that_member_is_not_last_administrator(group_id, actor_id)},
         {:ok, _} <-
           Mobilizon.Actors.delete_member(member) do
      {
        :ok,
        %{
          parent: %{
            id: group_id
          },
          actor: %{
            id: actor_id
          }
        }
      }
    else
      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}

      {:error, :member_not_found} ->
        {:error, "Member not found"}

      {:only_administrator, true} ->
        {:error, "You can't leave this group because you are the only administrator"}
    end
  end

  def leave_group(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to leave a group"}
  end

  def find_events_for_group(
        %Actor{id: group_id} = group,
        _args,
        %{
          context: %{
            current_user: %User{} = user
          }
        }
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)} do
      # TODO : Handle public / restricted to group members events
      {:ok, Events.list_organized_events_for_group(group)}
    else
      {:member, false} ->
        {:ok, %Page{total: 0, elements: []}}
    end
  end

  def find_events_for_group(_parent, _args, _resolution) do
    {:ok, %Page{total: 0, elements: []}}
  end

  # We check that the actor asking to leave the group is not it's only administrator
  # We start by fetching the list of administrator or creators and if there's only one of them
  # and that it's the actor requesting leaving the group we return true
  @spec check_that_member_is_not_last_administrator(integer, integer) :: boolean
  defp check_that_member_is_not_last_administrator(group_id, actor_id) do
    case Actors.list_administrator_members_for_group(group_id) do
      %Page{total: total} when total > 1 ->
        true

      %Page{
        total: 1,
        elements: [
          %Member{
            actor: %Actor{
              id: member_actor_id
            }
          }
        ]
      } ->
        actor_id == member_actor_id

      _ ->
        false
    end
  end

  defp restrict_fields_for_non_member_request(%Actor{} = group) do
    Map.merge(
      group,
      %{
        followers: [],
        followings: [],
        organized_events: [],
        comments: [],
        feed_tokens: []
      }
    )
  end
end
