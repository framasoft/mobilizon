defmodule Mobilizon.GraphQL.Schema.Todos.TodoType do
  @moduledoc """
  Schema representation for Todos
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Mobilizon.GraphQL.Resolvers.Todos, as: TodoResolver
  alias Mobilizon.{Actors, Todos}

  @desc "A todo"
  object :todo do
    field(:id, :id, description: "The todo's ID")
    field(:title, :string, description: "The todo's title")
    field(:status, :boolean, description: "The todo's status")
    field(:due_date, :datetime, description: "The todo's due date")
    field(:creator, :actor, resolve: dataloader(Actors), description: "The todo's creator")

    field(:todo_list, :todo_list,
      resolve: dataloader(Todos),
      description: "The todo list this todo is attached to"
    )

    field(:assigned_to, :actor,
      resolve: dataloader(Actors),
      description: "The todos's assigned person"
    )
  end

  @desc """
  A paginated list of todos
  """
  object :paginated_todo_list do
    field(:elements, list_of(:todo), description: "A list of todos")
    field(:total, :integer, description: "The total number of todos in the list")
  end

  object :todo_queries do
    @desc "Get a todo"
    field :todo, :todo do
      arg(:id, non_null(:id), description: "The todo ID")
      resolve(&TodoResolver.get_todo/3)
    end
  end

  object :todo_mutations do
    @desc "Create a todo"
    field :create_todo, :todo do
      arg(:todo_list_id, non_null(:id), description: "The todo-list ID this todo is in")
      arg(:title, non_null(:string), description: "The todo title")
      arg(:status, :boolean, description: "The todo status")
      arg(:due_date, :datetime, description: "The todo due date")
      arg(:assigned_to_id, :id, description: "The actor this todo is assigned to")

      resolve(&TodoResolver.create_todo/3)
    end

    @desc "Update a todo"
    field :update_todo, :todo do
      arg(:id, non_null(:id), description: "The todo ID")
      arg(:todo_list_id, :id, description: "The new todo-list ID")
      arg(:title, :string, description: "The new todo title")
      arg(:status, :boolean, description: "The new todo status")
      arg(:due_date, :datetime, description: "The new todo due date")
      arg(:assigned_to_id, :id, description: "The new id of the actor this todo is assigned to")

      resolve(&TodoResolver.update_todo/3)
    end

    # @desc "Delete a todo"
    # field :delete_todo, :deleted_object do
    #   arg(:id, non_null(:id))
    #   resolve(&TodoResolver.delete_todo/3)
    # end
  end
end
