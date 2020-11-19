defmodule Mobilizon.GraphQL.Resolvers.Todos do
  @moduledoc """
  Handles the todos related GraphQL calls
  """

  alias Mobilizon.{Actors, Todos, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Storage.Page
  alias Mobilizon.Todos.{Todo, TodoList}
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  require Logger

  @doc """
  Find todo lists for group.

  Returns only if actor requesting is a member of the group
  """
  def find_todo_lists_for_group(
        %Actor{id: group_id} = group,
        _args,
        %{
          context: %{current_user: %User{} = user}
        } = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         %Page{} = page <- Todos.get_todo_lists_for_group(group) do
      {:ok, page}
    else
      {:member, _} ->
        with %Page{} = page <- Todos.get_todo_lists_for_group(group) do
          {:ok, %Page{page | elements: []}}
        end
    end
  end

  def find_todo_lists_for_group(_parent, _args, _resolution) do
    {:ok, %Page{total: 0, elements: []}}
  end

  def find_todos_for_todo_list(
        %TodoList{actor_id: group_id} = todo_list,
        _args,
        %{
          context: %{current_user: %User{} = user}
        } = _resolution
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         %Page{} = page <- Todos.get_todos_for_todo_list(todo_list) do
      {:ok, page}
    else
      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  def get_todo_list(
        _parent,
        %{id: todo_list_id},
        %{
          context: %{current_user: %User{} = user}
        } = _resolution
      ) do
    with {:actor, %Actor{id: actor_id}} <- {:actor, Users.get_actor_for_user(user)},
         {:todo, %TodoList{actor_id: group_id} = todo} <-
           {:todo, Todos.get_todo_list(todo_list_id)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)} do
      {:ok, todo}
    else
      {:todo, nil} ->
        {:error, dgettext("errors", "Todo list doesn't exist")}

      {:actor, nil} ->
        {:error, dgettext("errors", "No profile found for user")}

      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  def create_todo_list(
        _parent,
        %{group_id: group_id} = args,
        %{
          context: %{current_user: %User{} = user}
        } = _resolution
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:ok, _, %TodoList{} = todo_list} <-
           ActivityPub.create(:todo_list, Map.put(args, :actor_id, group_id), true, %{}) do
      {:ok, todo_list}
    else
      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  # def update_todo_list(
  #       _parent,
  #       %{id: todo_list_id, actor_id: actor_id},
  #       %{
  #         context: %{current_user: %User{} = user}
  #       } = _resolution
  #     ) do
  #   with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
  #        {:todo_list, %TodoList{actor_id: group_id} = todo_list} <-
  #          {:todo_list, Todos.get_todo_list(todo_list_id)},
  #        {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
  #        {:ok, _, %TodoList{} = todo} <-
  #          ActivityPub.update_todo_list(todo_list, actor, true, %{}) do
  #     {:ok, todo}
  #   else
  #     {:todo_list, _} ->
  #       {:error, "Todo list doesn't exist"}

  #     {:member, _} ->
  #       {:error, "Profile is not member of group"}
  #   end
  # end

  # def delete_todo_list(
  #       _parent,
  #       %{id: todo_list_id, actor_id: actor_id},
  #       %{
  #         context: %{current_user: %User{} = user}
  #       } = _resolution
  #     ) do
  #   with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
  #        {:todo_list, %TodoList{actor_id: group_id} = todo_list} <-
  #          {:todo_list, Todos.get_todo_list(todo_list_id)},
  #        {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
  #        {:ok, _, %TodoList{} = todo} <-
  #          ActivityPub.delete_todo_list(todo_list, actor, true, %{}) do
  #     {:ok, todo}
  #   else
  #     {:todo_list, _} ->
  #       {:error, "Todo list doesn't exist"}

  #     {:member, _} ->
  #       {:error, "Profile is not member of group"}
  #   end
  # end

  def get_todo(
        _parent,
        %{id: todo_id},
        %{
          context: %{current_user: %User{} = user}
        } = _resolution
      ) do
    with {:actor, %Actor{id: actor_id}} <- {:actor, Users.get_actor_for_user(user)},
         {:todo, %Todo{todo_list_id: todo_list_id} = todo} <-
           {:todo, Todos.get_todo(todo_id)},
         {:todo_list, %TodoList{actor_id: group_id}} <-
           {:todo_list, Todos.get_todo_list(todo_list_id)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)} do
      {:ok, todo}
    else
      {:todo, nil} ->
        {:error, dgettext("errors", "Todo doesn't exist")}

      {:actor, nil} ->
        {:error, dgettext("errors", "No profile found for user")}

      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  def create_todo(
        _parent,
        %{todo_list_id: todo_list_id} = args,
        %{
          context: %{current_user: %User{} = user}
        } = _resolution
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:todo_list, %TodoList{actor_id: group_id} = _todo_list} <-
           {:todo_list, Todos.get_todo_list(todo_list_id)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:ok, _, %Todo{} = todo} <-
           ActivityPub.create(:todo, Map.put(args, :creator_id, actor_id), true, %{}) do
      {:ok, todo}
    else
      {:todo_list, _} ->
        {:error, dgettext("errors", "Todo list doesn't exist")}

      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  def update_todo(
        _parent,
        %{id: todo_id} = args,
        %{
          context: %{current_user: %User{} = user}
        } = _resolution
      ) do
    with {:actor, %Actor{id: actor_id} = _actor} <- {:actor, Users.get_actor_for_user(user)},
         {:todo, %Todo{todo_list_id: todo_list_id} = todo} <-
           {:todo, Todos.get_todo(todo_id)},
         {:todo_list, %TodoList{actor_id: group_id}} <-
           {:todo_list, Todos.get_todo_list(todo_list_id)},
         {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
         {:ok, _, %Todo{} = todo} <-
           ActivityPub.update(todo, args, true, %{}) do
      {:ok, todo}
    else
      {:todo_list, _} ->
        {:error, dgettext("errors", "Todo list doesn't exist")}

      {:todo, _} ->
        {:error, dgettext("errors", "Todo doesn't exist")}

      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  # def delete_todo(
  #       _parent,
  #       %{id: todo_id, actor_id: actor_id},
  #       %{
  #         context: %{current_user: %User{} = user}
  #       } = _resolution
  #     ) do
  #   with {:is_owned, %Actor{} = actor} <- User.owns_actor(user, actor_id),
  #        {:todo, %Todo{todo_list_id: todo_list_id} = todo} <-
  #          {:todo, Todos.get_todo(todo_id)},
  #        {:todo_list, %TodoList{actor_id: group_id}} <-
  #          {:todo_list, Todos.get_todo_list(todo_list_id)},
  #        {:member, true} <- {:member, Actors.is_member?(actor_id, group_id)},
  #        {:ok, _, %Todo{} = todo} <-
  #          ActivityPub.delete_todo(todo, actor, true, %{}) do
  #     {:ok, todo}
  #   else
  #     {:todo_list, _} ->
  #       {:error, "Todo list doesn't exist"}

  #     {:todo, _} ->
  #       {:error, "Todo doesn't exist"}

  #     {:member, _} ->
  #       {:error, "Profile is not member of group"}
  #   end
  # end
end
