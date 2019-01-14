defmodule MobilizonWeb.Schema.Events.CategoryType do
  @moduledoc """
  Schema representation for Category
  """
  use Absinthe.Schema.Notation

  @desc "A category"
  object :category do
    field(:id, :id, description: "The category's ID")
    field(:description, :string, description: "The category's description")
    field(:picture, :picture, description: "The category's picture")
    field(:title, :string, description: "The category's title")
  end
end
