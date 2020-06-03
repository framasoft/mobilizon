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

  object :paginated_todo_list do
    field(:elements, list_of(:todo), description: "A list of todos")
    field(:total, :integer, description: "The total number of todos in the list")
  end

  object :todo_queries do
    @desc "Get a todo"
    field :todo, :todo do
      arg(:id, non_null(:id))
      resolve(&TodoResolver.get_todo/3)
    end
  end

  object :todo_mutations do
    @desc "Create a todo"
    field :create_todo, :todo do
      arg(:todo_list_id, non_null(:id))
      arg(:title, non_null(:string))
      arg(:status, :boolean)
      arg(:due_date, :datetime)
      arg(:assigned_to_id, :id)

      resolve(&TodoResolver.create_todo/3)
    end

    @desc "Update a todo"
    field :update_todo, :todo do
      arg(:id, non_null(:id))
      arg(:todo_list_id, :id)
      arg(:title, :string)
      arg(:status, :boolean)
      arg(:due_date, :datetime)
      arg(:assigned_to_id, :id)

      resolve(&TodoResolver.update_todo/3)
    end

    # @desc "Delete a todo"
    # field :delete_todo, :deleted_object do
    #   arg(:id, non_null(:id))
    #   resolve(&TodoResolver.delete_todo/3)
    # end
  end
end
