defmodule Mobilizon.GraphQL.Schema.Discussions.DiscussionType do
  @moduledoc """
  Schema representation for discussion
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.Actors
  alias Mobilizon.GraphQL.Resolvers.Discussion

  @desc "A discussion"
  object :discussion do
    field(:id, :id, description: "Internal ID for this discussion")
    field(:title, :string, description: "The title for this discussion")
    field(:slug, :string, description: "The slug for the discussion")
    field(:last_comment, :comment, description: "The last comment of the discussion")

    field :comments, :paginated_comment_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Discussion.get_comments_for_discussion/3)
      description("The comments for the discussion")
    end

    field(:creator, :person,
      resolve: dataloader(Actors),
      description: "This discussions's creator"
    )

    field(:actor, :actor, resolve: dataloader(Actors), description: "This discussion's group")
    field(:inserted_at, :datetime, description: "When was this discussion's created")
    field(:updated_at, :datetime, description: "When was this discussion's updated")
  end

  @desc "A paginated list of discussions"
  object :paginated_discussion_list do
    field(:elements, list_of(:discussion), description: "A list of discussion")
    field(:total, :integer, description: "The total number of discussions in the list")
  end

  object :discussion_queries do
    @desc "Get a discussion"
    field :discussion, type: :discussion do
      arg(:id, :id, description: "The discussion's ID")
      arg(:slug, :string, description: "The discussion's slug")
      resolve(&Discussion.get_discussion/3)
    end
  end

  object :discussion_mutations do
    @desc "Create a discussion"
    field :create_discussion, type: :discussion do
      arg(:title, non_null(:string), description: "The discussion's title")
      arg(:text, non_null(:string), description: "The discussion's first comment body")
      arg(:actor_id, non_null(:id), description: "The discussion's group ID")

      resolve(&Discussion.create_discussion/3)
    end

    @desc "Reply to a discussion"
    field :reply_to_discussion, type: :discussion do
      arg(:discussion_id, non_null(:id), description: "The discussion's ID")
      arg(:text, non_null(:string), description: "The discussion's reply body")
      resolve(&Discussion.reply_to_discussion/3)
    end

    @desc "Update a discussion"
    field :update_discussion, type: :discussion do
      arg(:title, non_null(:string), description: "The updated discussion's title")
      arg(:discussion_id, non_null(:id), description: "The discussion's ID")
      resolve(&Discussion.update_discussion/3)
    end

    @desc "Delete a discussion"
    field :delete_discussion, type: :discussion do
      arg(:discussion_id, non_null(:id), description: "The discussion's ID")

      resolve(&Discussion.delete_discussion/3)
    end
  end

  object :discussion_subscriptions do
    @desc "Notify when a discussion changed"
    field :discussion_comment_changed, :discussion do
      arg(:slug, non_null(:string), description: "The discussion's slug")

      config(fn args, _ ->
        {:ok, topic: args.slug}
      end)
    end
  end
end
