defmodule Mobilizon.Todos.Todo do
  @moduledoc """
  Represents a todo, or task
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Mobilizon.Storage.Ecto, only: [ensure_url: 2, maybe_add_published_at: 1]
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Todos.TodoList

  @type t :: %__MODULE__{
          status: boolean(),
          title: String.t(),
          due_date: DateTime.t(),
          todo_list: TodoList.t(),
          creator: Actor.t(),
          assigned_to: Actor.t(),
          local: boolean,
          published_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "todos" do
    field(:status, :boolean, default: false)
    field(:title, :string)
    field(:url, :string)
    field(:due_date, :utc_datetime)
    field(:local, :boolean, default: true)
    field(:published_at, :utc_datetime)
    belongs_to(:todo_list, TodoList, type: :binary_id)
    belongs_to(:creator, Actor)
    belongs_to(:assigned_to, Actor)

    timestamps()
  end

  @required_attrs [:title, :creator_id, :url, :todo_list_id, :published_at]
  @optional_attrs [:status, :due_date, :assigned_to_id, :local]
  @attrs @required_attrs ++ @optional_attrs

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, @attrs)
    |> ensure_url(:todo)
    |> maybe_add_published_at()
    |> validate_required(@required_attrs)
  end
end
