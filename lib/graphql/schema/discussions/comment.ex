defmodule Mobilizon.GraphQL.Schema.Discussions.CommentType do
  @moduledoc """
  Schema representation for Comment
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.{Actors, Discussions}
  alias Mobilizon.GraphQL.Resolvers.Comment

  @desc "A comment"
  object :comment do
    interfaces([:action_log_object])
    field(:id, :id, description: "Internal ID for this comment")
    field(:uuid, :uuid)
    field(:url, :string)
    field(:local, :boolean)
    field(:visibility, :comment_visibility)
    field(:text, :string)
    field(:primaryLanguage, :string)

    field(:replies, list_of(:comment)) do
      resolve(dataloader(Discussions))
    end

    field(:total_replies, :integer)
    field(:in_reply_to_comment, :comment, resolve: dataloader(Discussions))
    field(:event, :event, resolve: dataloader(Events))
    field(:origin_comment, :comment, resolve: dataloader(Discussions))
    field(:threadLanguages, non_null(list_of(:string)))
    field(:actor, :person, resolve: dataloader(Actors))
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
    field(:deleted_at, :datetime)
  end

  @desc "The list of visibility options for a comment"
  enum :comment_visibility do
    value(:public, description: "Publicly listed and federated. Can be shared.")
    value(:unlisted, description: "Visible only to people with the link - or invited")

    value(:private,
      description: "Visible only to people members of the group or followers of the person"
    )

    value(:moderated, description: "Visible only after a moderator accepted")
    value(:invite, description: "visible only to people invited")
  end

  object :paginated_comment_list do
    field(:elements, list_of(:comment), description: "A list of comments")
    field(:total, :integer, description: "The total number of comments in the list")
  end

  object :comment_queries do
    @desc "Get replies for thread"
    field :thread, type: list_of(:comment) do
      arg(:id, :id)
      resolve(&Comment.get_thread/3)
    end
  end

  object :comment_mutations do
    @desc "Create a comment"
    field :create_comment, type: :comment do
      arg(:text, non_null(:string))
      arg(:event_id, :id)
      arg(:in_reply_to_comment_id, :id)
      arg(:actor_id, non_null(:id))

      resolve(&Comment.create_comment/3)
    end

    @desc "Update a comment"
    field :update_comment, type: :comment do
      arg(:text, non_null(:string))
      arg(:comment_id, non_null(:id))

      resolve(&Comment.update_comment/3)
    end

    field :delete_comment, type: :comment do
      arg(:comment_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Comment.delete_comment/3)
    end
  end
end
