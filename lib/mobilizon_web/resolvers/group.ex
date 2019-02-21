defmodule MobilizonWeb.Resolvers.Group do
  @moduledoc """
  Handles the group-related GraphQL calls
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, User, Member}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Activity
  require Logger

  @doc """
  Find a group
  """
  def find_group(_parent, %{preferred_username: name}, _resolution) do
    case ActivityPub.find_or_make_group_from_nickname(name) do
      {:ok, actor} ->
        {:ok, actor}

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
          context: %{current_user: _user}
        }
      ) do
    with {:ok, %Activity{data: %{"object" => %{"type" => "Group"} = object}}} <-
           MobilizonWeb.API.Groups.create_group(args) do
      {:ok,
       %Actor{
         preferred_username: object["preferredUsername"],
         summary: object["summary"],
         type: :Group,
         #  uuid: object["uuid"],
         url: object["id"]
       }}
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
end
