defmodule MobilizonWeb.Schema.CommentType do
  use Absinthe.Schema.Notation

  @desc "A comment"
  object :comment do
    field(:uuid, :uuid)
    field(:url, :string)
    field(:local, :boolean)
    field(:text, :string)
    field(:primaryLanguage, :string)
    field(:replies, list_of(:comment))
    field(:threadLanguages, non_null(list_of(:string)))
  end
end
