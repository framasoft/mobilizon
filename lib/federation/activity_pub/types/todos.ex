defmodule Mobilizon.Federation.ActivityPub.Types.Todos do
  @moduledoc """
  ActivityPub type handler for Todos
  """
  alias Mobilizon.{Actors, Todos}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Permission
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Todos.{Todo, TodoList}
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]
  require Logger

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) ::
          {:ok, Todo.t(), ActivityStream.t()} | {:error, Ecto.Changeset.t() | atom()}
  def create(args, additional) do
    with {:ok, %Todo{todo_list_id: todo_list_id, creator_id: creator_id} = todo} <-
           Todos.create_todo(args),
         {:ok, %Actor{} = creator, %TodoList{} = todo_list, %Actor{} = group} <-
           creator_todo_list_and_group(creator_id, todo_list_id) do
      todo = %{todo | todo_list: %{todo_list | actor: group}, creator: creator}
      todo_as_data = Convertible.model_to_as(todo)
      audience = %{"to" => [group.members_url], "cc" => []}
      create_data = make_create_data(todo_as_data, Map.merge(audience, additional))
      {:ok, todo, create_data}
    end
  end

  @impl Entity
  @spec update(Todo.t(), map, map) ::
          {:ok, Todo.t(), ActivityStream.t()}
          | {:error, atom() | Ecto.Changeset.t()}
  def update(%Todo{} = old_todo, args, additional) do
    with {:ok, %Todo{todo_list_id: todo_list_id} = todo} <- Todos.update_todo(old_todo, args),
         {:ok, %TodoList{} = todo_list, %Actor{} = group} <- todo_list_and_group(todo_list_id) do
      todo_as_data = Convertible.model_to_as(%{todo | todo_list: %{todo_list | actor: group}})
      audience = %{"to" => [group.members_url], "cc" => []}
      update_data = make_update_data(todo_as_data, Map.merge(audience, additional))
      {:ok, todo, update_data}
    end
  end

  @spec creator_todo_list_and_group(integer(), String.t()) ::
          {:ok, Actor.t(), TodoList.t(), Actor.t()}
          | {:error, :creator_not_found | :group_not_found | :todo_list_not_found}
  defp creator_todo_list_and_group(creator_id, todo_list_id) do
    case Actors.get_actor(creator_id) do
      %Actor{} = creator ->
        case todo_list_and_group(todo_list_id) do
          {:ok, %TodoList{} = todo_list, %Actor{} = group} ->
            {:ok, creator, todo_list, group}

          {:error, err} ->
            {:error, err}
        end

      nil ->
        {:error, :creator_not_found}
    end
  end

  @spec todo_list_and_group(String.t()) ::
          {:ok, TodoList.t(), Actor.t()} | {:error, :group_not_found | :todo_list_not_found}
  defp todo_list_and_group(todo_list_id) do
    case Todos.get_todo_list(todo_list_id) do
      %TodoList{actor_id: group_id} = todo_list ->
        case Actors.get_group_by_actor_id(group_id) do
          {:ok, %Actor{} = group} ->
            {:ok, todo_list, group}

          {:error, :group_not_found} ->
            {:error, :group_not_found}
        end

      nil ->
        {:error, :todo_list_not_found}
    end
  end

  @impl Entity
  @spec delete(Todo.t(), Actor.t(), any(), any()) ::
          {:ok, ActivityStream.t(), Actor.t(), Todo.t()} | {:error, Ecto.Changeset.t()}
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
      "id" => "#{url}/delete",
      "to" => [group_url]
    }

    case Todos.delete_todo(todo) do
      {:ok, _todo} ->
        Cachex.del(:activity_pub, "todo_#{todo.id}")
        {:ok, activity_data, actor, todo}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec actor(Todo.t()) :: Actor.t() | nil
  def actor(%Todo{creator_id: creator_id}), do: Actors.get_actor(creator_id)

  @spec group_actor(Todo.t()) :: Actor.t() | nil
  def group_actor(%Todo{todo_list_id: todo_list_id}) do
    case Todos.get_todo_list(todo_list_id) do
      %TodoList{actor_id: group_id} ->
        Actors.get_actor(group_id)

      _ ->
        nil
    end
  end

  @spec permissions(Todo.t()) :: Permission.t()
  def permissions(%Todo{}) do
    %Permission{access: :member, create: :member, update: :member, delete: :member}
  end
end
