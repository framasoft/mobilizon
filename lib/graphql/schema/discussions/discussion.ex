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
    field(:title, :string)
    field(:slug, :string)
    field(:last_comment, :comment)

    field :comments, :paginated_comment_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Discussion.get_comments_for_discussion/3)
      description("The comments for the discussion")
    end

    field(:creator, :person, resolve: dataloader(Actors))
    field(:actor, :actor, resolve: dataloader(Actors))
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :paginated_discussion_list do
    field(:elements, list_of(:discussion), description: "A list of discussion")
    field(:total, :integer, description: "The total number of comments in the list")
  end

  object :discussion_queries do
    @desc "Get a discussion"
    field :discussion, type: :discussion do
      arg(:id, :id)
      arg(:slug, :string)
      resolve(&Discussion.get_discussion/3)
    end
  end

  object :discussion_mutations do
    @desc "Create a discussion"
    field :create_discussion, type: :discussion do
      arg(:title, non_null(:string))
      arg(:text, non_null(:string))
      arg(:actor_id, non_null(:id))
      arg(:creator_id, non_null(:id))

      resolve(&Discussion.create_discussion/3)
    end

    field :reply_to_discussion, type: :discussion do
      arg(:discussion_id, non_null(:id))
      arg(:text, non_null(:string))
      resolve(&Discussion.reply_to_discussion/3)
    end

    field :update_discussion, type: :discussion do
      arg(:title, non_null(:string))
      arg(:discussion_id, non_null(:id))
      resolve(&Discussion.update_discussion/3)
    end

    field :delete_discussion, type: :discussion do
      arg(:discussion_id, non_null(:id))

      resolve(&Discussion.delete_discussion/3)
    end
  end

  object :discussion_subscriptions do
    field :discussion_comment_changed, :discussion do
      arg(:slug, non_null(:string))

      config(fn args, _ ->
        {:ok, topic: args.slug}
      end)
    end
  end
end
