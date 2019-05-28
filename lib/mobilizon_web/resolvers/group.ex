defmodule MobilizonWeb.Resolvers.Group do
  @moduledoc """
  Handles the group-related GraphQL calls
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Users.User
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Activity
  alias MobilizonWeb.Resolvers.Person
  require Logger

  @doc """
  Find a group
  """
  def find_group(_parent, %{preferred_username: name}, _resolution) do
    with {:ok, actor} <- ActivityPub.find_or_make_group_from_nickname(name),
         actor <- Person.proxify_pictures(actor) do
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
    {:ok,
     Actors.list_groups(page, limit) |> Enum.map(fn actor -> Person.proxify_pictures(actor) end)}
  end

  @doc """
  Create a new group. The creator is automatically added as admin
  """
  def create_group(
        _parent,
        args,
        %{
          context: %{
            current_user: _user
          }
        }
      ) do
    with {
           :ok,
           %Activity{
             data: %{
               "object" => %{"type" => "Group"} = object
             }
           }
         } <-
           MobilizonWeb.API.Groups.create_group(args) do
      {
        :ok,
        %Actor{
          preferred_username: object["preferredUsername"],
          summary: object["summary"],
          type: :Group,
          #  uuid: object["uuid"],
          url: object["id"]
        }
      }
    end

    # with %Actor{id: actor_id} <- Actors.get_local_actor_by_name(actor_username),
    #      {:user_actor, true} <-
    #        {:user_actor, actor_id in Enum.map(Actors.get_actors_for_user(user), & &1.id)},
    #      {:ok, %Actor{} = group} <- Actors.create_group(%{preferred_username: preferred_username}) do
    #   {:ok, group}
    # else
    #   {:error, %Ecto.Changeset{errors: [url: {"has already been taken", []}]}} ->
    #     {:error, :group_name_not_available}

    #   err ->
    #     Logger.error(inspect(err))
    #     err
    # end
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
    with {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         {:is_owned, true, _} <- User.owns_actor(user, actor_id),
         {:ok, %Member{} = member} <- Member.get_member(actor_id, group.id),
         {:is_admin, true} <- Member.is_administrator(member),
         group <- Actors.delete_group!(group) do
      {:ok, %{id: group.id}}
    else
      {:error, :group_not_found} ->
        {:error, "Group not found"}

      {:is_owned, false} ->
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
    with {:is_owned, true, actor} <- User.owns_actor(user, actor_id),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         {:error, :member_not_found} <- Member.get_member(actor.id, group.id),
         {:is_able_to_join, true} <- {:is_able_to_join, Member.can_be_joined(group)},
         role <- Mobilizon.Actors.get_default_member_role(group),
         {:ok, _} <-
           Actors.create_member(%{
             parent_id: group.id,
             actor_id: actor.id,
             role: role
           }) do
      {:ok,
       %{
         parent: group |> Person.proxify_pictures(),
         actor: actor |> Person.proxify_pictures(),
         role: role
       }}
    else
      {:is_owned, false} ->
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
    with {:is_owned, true, actor} <- User.owns_actor(user, actor_id),
         {:ok, %Member{} = member} <- Member.get_member(actor.id, group_id),
         {:only_administrator, false} <-
           {:only_administrator, check_that_member_is_not_only_administrator(group_id, actor_id)},
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
      {:is_owned, false} ->
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

  # We check that the actor asking to leave the group is not it's only administrator
  # We start by fetching the list of administrator or creators and if there's only one of them
  # and that it's the actor requesting leaving the group we return true
  @spec check_that_member_is_not_only_administrator(integer(), integer()) :: boolean()
  defp check_that_member_is_not_only_administrator(group_id, actor_id) do
    with [
           %Member{
             actor: %Actor{
               id: member_actor_id
             }
           }
         ] <-
           Member.list_administrator_members_for_group(group_id) do
      actor_id == member_actor_id
    else
      _ -> false
    end
  end
end
