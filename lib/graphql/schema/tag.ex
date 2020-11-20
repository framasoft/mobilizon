defmodule Mobilizon.GraphQL.Schema.TagType do
  @moduledoc """
  Schema representation for Tags
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Tag

  @desc "A tag"
  object :tag do
    field(:id, :id, description: "The tag's ID")
    field(:slug, :string, description: "The tags's slug")
    field(:title, :string, description: "The tag's title")

    field(
      :related,
      list_of(:tag),
      resolve: &Tag.get_related_tags/3,
      description: "Related tags to this tag"
    )
  end

  object :tag_queries do
    @desc "Get the list of tags"
    field :tags, non_null(list_of(:tag)) do
      arg(:page, :integer, default_value: 1, description: "The page in the paginated tags list")
      arg(:limit, :integer, default_value: 10, description: "The limit of tags per page")
      resolve(&Tag.list_tags/3)
    end
  end
end
