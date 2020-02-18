defmodule Mobilizon.Todos.TodoList do
  @moduledoc """
  Represents a todo list, or task list
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Mobilizon.Storage.Ecto, only: [ensure_url: 2]
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Todos.Todo

  @type t :: %__MODULE__{
          title: String.t(),
          todos: [Todo.t()],
          actor: Actor.t(),
          local: boolean
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "todo_lists" do
    field(:title, :string)
    field(:url, :string)
    field(:local, :boolean, default: true)

    belongs_to(:actor, Actor)
    has_many(:todos, Todo)

    timestamps()
  end

  @required_attrs [:title, :url, :actor_id]
  @optional_attrs [:local]
  @attrs @required_attrs ++ @optional_attrs

  @doc false
  def changeset(todo_list, attrs) do
    todo_list
    |> cast(attrs, @attrs)
    |> ensure_url(:todo_list)
    |> validate_required(@required_attrs)
  end
end
