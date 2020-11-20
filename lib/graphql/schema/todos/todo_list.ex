defmodule Mobilizon.GraphQL.Schema.Todos.TodoListType do
  @moduledoc """
  Schema representation for Todo Lists
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Mobilizon.Actors
  alias Mobilizon.GraphQL.Resolvers.Todos

  @desc "A todo list"
  object :todo_list do
    field(:id, :id, description: "The todo list's ID")
    field(:title, :string, description: "The todo list's title")

    field(:actor, :actor,
      resolve: dataloader(Actors),
      description: "The actor that owns this todo list"
    )

    field(:todos, :paginated_todo_list,
      resolve: &Todos.find_todos_for_todo_list/3,
      description: "The todo-list's todos"
    )
  end

  @desc """
  A paginated list of todo-lists
  """
  object :paginated_todo_list_list do
    field(:elements, list_of(:todo_list), description: "A list of todo lists")
    field(:total, :integer, description: "The total number of todo lists in the list")
  end

  object :todo_list_queries do
    @desc "Get a todo list"
    field :todo_list, :todo_list do
      arg(:id, non_null(:id), description: "The todo-list ID")
      resolve(&Todos.get_todo_list/3)
    end
  end

  object :todo_list_mutations do
    @desc "Create a todo list"
    field :create_todo_list, :todo_list do
      arg(:title, non_null(:string), description: "The todo list title")
      arg(:group_id, non_null(:id), description: "The group ID")
      resolve(&Todos.create_todo_list/3)
    end
  end
end
