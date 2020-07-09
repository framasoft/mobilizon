defmodule Mobilizon.GraphQL.Schema.PostType do
  @moduledoc """
  Schema representation for Posts
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.GraphQL.Resolvers.{Post, Tag}

  @desc "A post"
  object :post do
    field(:id, :id, description: "The post's ID")
    field(:title, :string, description: "The post's title")
    field(:slug, :string, description: "The post's slug")
    field(:body, :string, description: "The post's body, as HTML")
    field(:url, :string, description: "The post's URL")
    field(:draft, :boolean, description: "Whether the post is a draft")
    field(:author, :actor, description: "The post's author")
    field(:attributed_to, :actor, description: "The post's group")
    field(:visibility, :post_visibility, description: "The post's visibility")
    field(:publish_at, :datetime, description: "When the post was published")
    field(:inserted_at, :naive_datetime, description: "The post's creation date")
    field(:updated_at, :naive_datetime, description: "The post's last update date")

    field(:tags, list_of(:tag),
      resolve: &Tag.list_tags_for_post/3,
      description: "The post's tags"
    )
  end

  object :paginated_post_list do
    field(:elements, list_of(:post), description: "A list of posts")
    field(:total, :integer, description: "The total number of posts in the list")
  end

  @desc "The list of visibility options for a post"
  enum :post_visibility do
    value(:public, description: "Publicly listed and federated. Can be shared.")
    value(:unlisted, description: "Visible only to people with the link")
    # value(:restricted, description: "Visible only after a moderator accepted")

    value(:private,
      description: "Visible only to people members of the group or followers of the person"
    )
  end

  object :post_queries do
    @desc "Get a post"
    field :post, :post do
      arg(:slug, non_null(:string))
      resolve(&Post.get_post/3)
    end
  end

  object :post_mutations do
    @desc "Create a post"
    field :create_post, :post do
      arg(:attributed_to_id, non_null(:id))
      arg(:title, non_null(:string))
      arg(:body, :string)
      arg(:draft, :boolean, default_value: false)
      arg(:visibility, :post_visibility)
      arg(:publish_at, :datetime)

      arg(:tags, list_of(:string),
        default_value: [],
        description: "The list of tags associated to the post"
      )

      resolve(&Post.create_post/3)
    end

    @desc "Update a post"
    field :update_post, :post do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:attributed_to_id, :id)
      arg(:draft, :boolean)
      arg(:visibility, :post_visibility)
      arg(:publish_at, :datetime)
      arg(:tags, list_of(:string), description: "The list of tags associated to the post")

      resolve(&Post.update_post/3)
    end

    @desc "Delete a post"
    field :delete_post, :deleted_object do
      arg(:id, non_null(:id))
      resolve(&Post.delete_post/3)
    end
  end
end
