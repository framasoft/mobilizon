defmodule Mobilizon.GraphQL.Resolvers.Todos do
  @moduledoc """
  Handles the todos related GraphQL calls
  """

  alias Mobilizon.{Actors, Todos}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Storage.Page
  alias Mobilizon.Todos.{Todo, TodoList}
  import Mobilizon.Web.Gettext

  require Logger

  @doc """
  Find todo lists for group.

  Returns only if actor requesting is a member of the group
  """
  @spec find_todo_lists_for_group(Actor.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(TodoList.t())}
  def find_todo_lists_for_group(
        %Actor{id: group_id} = group,
        %{page: page, limit: limit},
        %{
          context: %{current_actor: %Actor{id: actor_id}}
        } = _resolution
      ) do
    with {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
         %Page{} = page <- Todos.get_todo_lists_for_group(group, page, limit) do
      {:ok, page}
    else
      {:member, _} ->
        with %Page{} = page <- Todos.get_todo_lists_for_group(group, page, limit) do
          {:ok, %Page{page | elements: []}}
        end
    end
  end

  def find_todo_lists_for_group(_parent, _args, _resolution) do
    {:ok, %Page{total: 0, elements: []}}
  end

  @spec find_todos_for_todo_list(TodoList.t(), map(), Absinthe.Resolution.t()) ::
          {:ok, Page.t(Todo.t())} | {:error, String.t()}
  def find_todos_for_todo_list(
        %TodoList{actor_id: group_id} = todo_list,
        %{page: page, limit: limit},
        %{
          context: %{current_actor: %Actor{id: actor_id}}
        } = _resolution
      ) do
    with {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
         %Page{} = page <- Todos.get_todos_for_todo_list(todo_list, page, limit) do
      {:ok, page}
    else
      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  @spec get_todo_list(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, TodoList.t()} | {:error, String.t()}
  def get_todo_list(
        _parent,
        %{id: todo_list_id},
        %{
          context: %{current_actor: %Actor{id: actor_id}}
        } = _resolution
      ) do
    with {:todo, %TodoList{actor_id: group_id} = todo} <-
           {:todo, Todos.get_todo_list(todo_list_id)},
         {:member, true} <- {:member, Actors.member?(actor_id, group_id)} do
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

  @spec create_todo_list(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, TodoList.t()} | {:error, String.t()}
  def create_todo_list(
        _parent,
        %{group_id: group_id} = args,
        %{
          context: %{current_actor: %Actor{id: actor_id}}
        } = _resolution
      ) do
    with {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
         {:ok, _, %TodoList{} = todo_list} <-
           Actions.Create.create(
             :todo_list,
             Map.put(args, :actor_id, group_id),
             true,
             %{}
           ) do
      {:ok, todo_list}
    else
      {:actor, nil} ->
        {:error, dgettext("errors", "No profile found for user")}

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
  #        {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
  #        {:ok, _, %TodoList{} = todo} <-
  #          Actions.Update.update_todo_list(todo_list, actor, true, %{}) do
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
  #        {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
  #        {:ok, _, %TodoList{} = todo} <-
  #          Actions.Delete.delete_todo_list(todo_list, actor, true, %{}) do
  #     {:ok, todo}
  #   else
  #     {:todo_list, _} ->
  #       {:error, "Todo list doesn't exist"}

  #     {:member, _} ->
  #       {:error, "Profile is not member of group"}
  #   end
  # end

  @spec get_todo(any(), map(), Absinthe.Resolution.t()) :: {:ok, Todo.t()} | {:error, String.t()}
  def get_todo(
        _parent,
        %{id: todo_id},
        %{
          context: %{current_actor: %Actor{id: actor_id}}
        } = _resolution
      ) do
    with {:todo, %Todo{todo_list_id: todo_list_id} = todo} <-
           {:todo, Todos.get_todo(todo_id)},
         {:todo_list, %TodoList{actor_id: group_id}} <-
           {:todo_list, Todos.get_todo_list(todo_list_id)},
         {:member, true} <- {:member, Actors.member?(actor_id, group_id)} do
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

  @spec create_todo(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Todo.t()} | {:error, String.t()}
  def create_todo(
        _parent,
        %{todo_list_id: todo_list_id} = args,
        %{
          context: %{current_actor: %Actor{id: actor_id}}
        } = _resolution
      ) do
    with {:todo_list, %TodoList{actor_id: group_id} = _todo_list} <-
           {:todo_list, Todos.get_todo_list(todo_list_id)},
         {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
         {:ok, _, %Todo{} = todo} <-
           Actions.Create.create(
             :todo,
             Map.put(args, :creator_id, actor_id),
             true,
             %{}
           ) do
      {:ok, todo}
    else
      {:actor, nil} ->
        {:error, dgettext("errors", "No profile found for user")}

      {:todo_list, _} ->
        {:error, dgettext("errors", "Todo list doesn't exist")}

      {:member, _} ->
        {:error, dgettext("errors", "Profile is not member of group")}
    end
  end

  @spec update_todo(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Todo.t()} | {:error, String.t()}
  def update_todo(
        _parent,
        %{id: todo_id} = args,
        %{
          context: %{current_actor: %Actor{id: actor_id}}
        } = _resolution
      ) do
    with {:todo, %Todo{todo_list_id: todo_list_id} = todo} <-
           {:todo, Todos.get_todo(todo_id)},
         {:todo_list, %TodoList{actor_id: group_id}} <-
           {:todo_list, Todos.get_todo_list(todo_list_id)},
         {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
         {:ok, _, %Todo{} = todo} <-
           Actions.Update.update(todo, args, true, %{}) do
      {:ok, todo}
    else
      {:actor, nil} ->
        {:error, dgettext("errors", "No profile found for user")}

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
  #        {:member, true} <- {:member, Actors.member?(actor_id, group_id)},
  #        {:ok, _, %Todo{} = todo} <-
  #          Actions.Delete.delete_todo(todo, actor, true, %{}) do
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
