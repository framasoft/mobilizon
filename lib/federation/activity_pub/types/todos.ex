defmodule Mobilizon.Federation.ActivityPub.Types.Todos do
  @moduledoc false
  alias Mobilizon.{Actors, Todos}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Todos.{Todo, TodoList}
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]
  require Logger

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) :: {:ok, map()}
  def create(args, additional) do
    with {:ok, %Todo{todo_list_id: todo_list_id, creator_id: creator_id} = todo} <-
           Todos.create_todo(args),
         %TodoList{actor_id: group_id} = todo_list <- Todos.get_todo_list(todo_list_id),
         %Actor{} = creator <- Actors.get_actor(creator_id),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         todo <- %{todo | todo_list: %{todo_list | actor: group}, creator: creator},
         todo_as_data <-
           Convertible.model_to_as(todo),
         audience <- %{"to" => [group.members_url], "cc" => []},
         create_data <-
           make_create_data(todo_as_data, Map.merge(audience, additional)) do
      {:ok, todo, create_data}
    end
  end

  @impl Entity
  @spec update(Todo.t(), map, map) :: {:ok, Todo.t(), Activity.t()} | any
  def update(%Todo{} = old_todo, args, additional) do
    with {:ok, %Todo{todo_list_id: todo_list_id} = todo} <- Todos.update_todo(old_todo, args),
         %TodoList{actor_id: group_id} = todo_list <- Todos.get_todo_list(todo_list_id),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id),
         todo_as_data <-
           Convertible.model_to_as(%{todo | todo_list: %{todo_list | actor: group}}),
         audience <- %{"to" => [group.members_url], "cc" => []},
         update_data <-
           make_update_data(todo_as_data, Map.merge(audience, additional)) do
      {:ok, todo, update_data}
    end
  end

  @impl Entity
  @spec delete(Todo.t(), Actor.t(), boolean(), map()) ::
          {:ok, ActivityStream.t(), Actor.t(), Todo.t()}
  def delete(
        %Todo{url: url, creator: %Actor{url: group_url}} = todo,
        %Actor{url: actor_url} = actor,
        _local,
        _additionnal
      ) do
    Logger.debug("Building Delete Todo activity")

    activity_data = %{
      "actor" => actor_url,
      "type" => "Delete",
      "object" => Convertible.model_to_as(url),
      "id" => url <> "/delete",
      "to" => [group_url]
    }

    with {:ok, _todo} <- Todos.delete_todo(todo),
         {:ok, true} <- Cachex.del(:activity_pub, "todo_#{todo.id}") do
      {:ok, activity_data, actor, todo}
    end
  end

  def actor(%Todo{creator_id: creator_id}), do: Actors.get_actor(creator_id)

  def group_actor(%Todo{todo_list_id: todo_list_id}) do
    case Todos.get_todo_list(todo_list_id) do
      %TodoList{actor_id: group_id} ->
        Actors.get_actor(group_id)

      _ ->
        nil
    end
  end

  def role_needed_to_update(%Todo{}), do: :member
  def role_needed_to_delete(%Todo{}), do: :member
end
