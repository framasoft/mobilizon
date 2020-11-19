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
    field(:uuid, :uuid, description: "An UUID for this comment")
    field(:url, :string, description: "Comment URL")
    field(:local, :boolean, description: "Whether this comment is local or not")
    field(:visibility, :comment_visibility, description: "The visibility for the comment")
    field(:text, :string, description: "The comment body")
    field(:primaryLanguage, :string, description: "The comment's primary language")

    field(:replies, list_of(:comment)) do
      description("A list of replies to the comment")
      resolve(dataloader(Discussions))
    end

    field(:total_replies, :integer,
      description: "The number of total known replies to this comment"
    )

    field(:in_reply_to_comment, :comment,
      resolve: dataloader(Discussions),
      description: "The comment this comment directly replies to"
    )

    field(:event, :event,
      resolve: dataloader(Events),
      description: "The eventual event this comment is under"
    )

    field(:origin_comment, :comment,
      resolve: dataloader(Discussions),
      description: "The original comment that started the thread this comment is in"
    )

    field(:threadLanguages, non_null(list_of(:string)), description: "The thread languages")
    field(:actor, :person, resolve: dataloader(Actors), description: "The comment's author")
    field(:inserted_at, :datetime, description: "When was the comment inserted in database")
    field(:updated_at, :datetime, description: "When was the comment updated")
    field(:deleted_at, :datetime, description: "When was the comment deleted")
    field(:published_at, :datetime, description: "When was the comment published")
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

  @desc "A paginated list of comments"
  object :paginated_comment_list do
    field(:elements, list_of(:comment), description: "A list of comments")
    field(:total, :integer, description: "The total number of comments in the list")
  end

  object :comment_queries do
    @desc "Get replies for thread"
    field :thread, type: list_of(:comment) do
      arg(:id, non_null(:id), description: "The comment ID")
      resolve(&Comment.get_thread/3)
    end
  end

  object :comment_mutations do
    @desc "Create a comment"
    field :create_comment, type: :comment do
      arg(:text, non_null(:string), description: "The comment's body")
      arg(:event_id, non_null(:id), description: "The event under which this comment is")
      arg(:in_reply_to_comment_id, :id, description: "The comment ID this one replies to")

      resolve(&Comment.create_comment/3)
    end

    @desc "Update a comment"
    field :update_comment, type: :comment do
      arg(:text, non_null(:string), description: "The comment updated body")
      arg(:comment_id, non_null(:id), description: "The comment ID")

      resolve(&Comment.update_comment/3)
    end

    @desc "Delete a single comment"
    field :delete_comment, type: :comment do
      arg(:comment_id, non_null(:id), description: "The comment ID")

      resolve(&Comment.delete_comment/3)
    end
  end
end
