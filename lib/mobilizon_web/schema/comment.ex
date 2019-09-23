defmodule MobilizonWeb.Schema.CommentType do
  @moduledoc """
  Schema representation for Comment
  """
  use Absinthe.Schema.Notation
  alias MobilizonWeb.Resolvers.Comment

  @desc "A comment"
  object :comment do
    field(:id, :id, description: "Internal ID for this comment")
    field(:uuid, :uuid)
    field(:url, :string)
    field(:local, :boolean)
    field(:visibility, :comment_visibility)
    field(:text, :string)
    field(:primaryLanguage, :string)
    field(:replies, list_of(:comment))
    field(:threadLanguages, non_null(list_of(:string)))
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

  object :comment_mutations do
    @desc "Create a comment"
    field :create_comment, type: :comment do
      arg(:text, non_null(:string))
      arg(:actor_username, non_null(:string))

      resolve(&Comment.create_comment/3)
    end
  end
end
