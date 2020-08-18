defmodule Mobilizon.Todos.TodoList do
  @moduledoc """
  Represents a todo list, or task list
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Mobilizon.Storage.Ecto, only: [ensure_url: 2, maybe_add_published_at: 1]
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Todos.Todo

  @type t :: %__MODULE__{
          title: String.t(),
          todos: [Todo.t()],
          actor: Actor.t(),
          local: boolean,
          published_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "todo_lists" do
    field(:title, :string)
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:published_at, :utc_datetime)
    belongs_to(:actor, Actor)
    has_many(:todos, Todo)

    timestamps()
  end

  @required_attrs [:title, :url, :actor_id, :published_at]
  @optional_attrs [:local]
  @attrs @required_attrs ++ @optional_attrs

  @doc false
  def changeset(todo_list, attrs) do
    todo_list
    |> cast(attrs, @attrs)
    |> ensure_url(:todo_list)
    |> maybe_add_published_at()
    |> validate_required(@required_attrs)
  end
end
