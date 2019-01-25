defmodule MobilizonWeb.Schema.Events.CategoryType do
  @moduledoc """
  Schema representation for Category
  """
  use Absinthe.Schema.Notation
  alias MobilizonWeb.Resolvers

  @desc "A category"
  object :category do
    field(:id, :id, description: "The category's ID")
    field(:description, :string, description: "The category's description")
    field(:picture, :picture, description: "The category's picture")
    field(:title, :string, description: "The category's title")
  end

  object :category_queries do
    @desc "Get the list of categories"
    field :categories, non_null(list_of(:category)) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Category.list_categories/3)
    end
  end

  object :category_mutations do
    @desc "Create a category with a title, description and picture"
    field :create_category, type: :category do
      arg(:title, non_null(:string))
      arg(:description, non_null(:string))
      arg(:picture, non_null(:upload))
      resolve(&Resolvers.Category.create_category/3)
    end
  end
end
