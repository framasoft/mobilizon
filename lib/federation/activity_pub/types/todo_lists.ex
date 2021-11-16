defmodule Mobilizon.Federation.ActivityPub.Types.TodoLists do
  @moduledoc false
  alias Mobilizon.{Actors, Todos}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Permission
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Todos.TodoList
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]
  require Logger

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) ::
          {:ok, TodoList.t(), ActivityStream.t()}
          | {:error, :group_not_found | Ecto.Changeset.t()}
  def create(args, additional) do
    with {:ok, %TodoList{actor_id: group_id} = todo_list} <- Todos.create_todo_list(args),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id) do
      todo_list_as_data = Convertible.model_to_as(%{todo_list | actor: group})
      audience = %{"to" => [group.members_url], "cc" => []}
      create_data = make_create_data(todo_list_as_data, Map.merge(audience, additional))
      {:ok, todo_list, create_data}
    end
  end

  @impl Entity
  @spec update(TodoList.t(), map, map) ::
          {:ok, TodoList.t(), ActivityStream.t()}
          | {:error, Ecto.Changeset.t() | :group_not_found}
  def update(%TodoList{} = old_todo_list, args, additional) do
    with {:ok, %TodoList{actor_id: group_id} = todo_list} <-
           Todos.update_todo_list(old_todo_list, args),
         {:ok, %Actor{} = group} <- Actors.get_group_by_actor_id(group_id) do
      todo_list_as_data = Convertible.model_to_as(%{todo_list | actor: group})
      audience = %{"to" => [group.members_url], "cc" => []}
      update_data = make_update_data(todo_list_as_data, Map.merge(audience, additional))
      {:ok, todo_list, update_data}
    end
  end

  @impl Entity
  @spec delete(TodoList.t(), Actor.t(), boolean(), map()) ::
          {:ok, ActivityStream.t(), Actor.t(), TodoList.t()} | {:error, Ecto.Changeset.t()}
  def delete(
        %TodoList{url: url, actor: %Actor{url: group_url}} = todo_list,
        %Actor{url: actor_url} = actor,
        _local,
        _additionnal
      ) do
    Logger.debug("Building Delete TodoList activity")

    activity_data = %{
      "actor" => actor_url,
      "type" => "Delete",
      "object" => %{
        "type" => "Tombstone",
        "formerType" => "TodoList",
        "deleted" => DateTime.utc_now(),
        "id" => url
      },
      "id" => url <> "/delete",
      "to" => [group_url]
    }

    case Todos.delete_todo_list(todo_list) do
      {:ok, _todo_list} ->
        Cachex.del(:activity_pub, "todo_list_#{todo_list.id}")
        {:ok, activity_data, actor, todo_list}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec actor(TodoList.t()) :: nil
  def actor(%TodoList{}), do: nil

  @spec group_actor(TodoList.t()) :: Actor.t() | nil
  def group_actor(%TodoList{actor_id: actor_id}), do: Actors.get_actor(actor_id)

  @spec permissions(TodoList.t()) :: Permission.t()
  def permissions(%TodoList{}) do
    %Permission{access: :member, create: :member, update: :member, delete: :member}
  end
end
