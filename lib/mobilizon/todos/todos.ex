defmodule Mobilizon.Todos do
  @moduledoc """
  The Todos context.
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Todos.{Todo, TodoList}
  import Ecto.Query

  @doc """
  Get a todo list by it's ID
  """
  @spec get_todo_list(integer | String.t()) :: TodoList.t() | nil
  def get_todo_list(id), do: Repo.get(TodoList, id)

  @doc """
  Get a todo list by it's URL
  """
  @spec get_todo_list_by_url(String.t()) :: TodoList.t() | nil
  def get_todo_list_by_url(url), do: Repo.get_by(TodoList, url: url)

  @doc """
  Returns the list of todo lists for a group.
  """
  @spec get_todo_lists_for_group(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def get_todo_lists_for_group(%Actor{id: group_id, type: :Group}, page \\ nil, limit \\ nil) do
    TodoList
    |> where(actor_id: ^group_id)
    |> order_by(desc: :updated_at)
    |> preload([:actor])
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of todos for a group.
  """
  @spec get_todos_for_todo_list(TodoList.t(), integer | nil, integer | nil) :: Page.t()
  def get_todos_for_todo_list(%TodoList{id: todo_list_id}, page \\ nil, limit \\ nil) do
    Todo
    |> where(todo_list_id: ^todo_list_id)
    |> order_by(asc: :status)
    # |> order_by(desc: :updated_at)
    |> Page.build_page(page, limit)
  end

  @doc """
  Creates a todo list.
  """
  @spec create_todo_list(map) :: {:ok, TodoList.t()} | {:error, Ecto.Changeset.t()}
  def create_todo_list(attrs \\ %{}) do
    %TodoList{}
    |> TodoList.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo list.
  """
  @spec update_todo_list(TodoList.t(), map) ::
          {:ok, TodoList.t()} | {:error, Ecto.Changeset.t()}
  def update_todo_list(%TodoList{} = todo_list, attrs) do
    todo_list
    |> TodoList.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo list
  """
  @spec delete_todo_list(TodoList.t()) :: {:ok, TodoList.t()} | {:error, Ecto.Changeset.t()}
  def delete_todo_list(%TodoList{} = todo_list), do: Repo.delete(todo_list)

  @doc """
  Get a todo by it's ID
  """
  @spec get_todo(integer | String.t()) :: Todo.t() | nil
  def get_todo(id), do: Repo.get(Todo, id)

  @doc """
  Get a todo by it's URL
  """
  @spec get_todo_by_url(String.t()) :: Todo.t() | nil
  def get_todo_by_url(url), do: Repo.get_by(Todo, url: url)

  @doc """
  Creates a todo.
  """
  @spec create_todo(map) :: {:ok, Todo.t()} | {:error, Ecto.Changeset.t()}
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo.
  """
  @spec update_todo(Todo.t(), map) :: {:ok, Todo.t()} | {:error, Ecto.Changeset.t()}
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo
  """
  @spec delete_todo(Todo.t()) :: {:ok, Todo.t()} | {:error, Ecto.Changeset.t()}
  def delete_todo(%Todo{} = todo), do: Repo.delete(todo)
end
