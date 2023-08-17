defimpl Mobilizon.Service.Metadata, for: Mobilizon.Discussions.Comment do
  alias Phoenix.HTML.Tag
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  import Mobilizon.Service.Metadata.Utils, only: [escape_text: 1]

  @spec build_tags(Comment.t(), String.t()) :: list(Phoenix.HTML.safe())
  def build_tags(%Comment{deleted_at: nil} = comment, _locale) do
    [
      Tag.tag(:meta,
        property: "og:title",
        content: escape_text(Actor.display_name(comment.actor))
      ),
      Tag.tag(:meta, property: "og:url", content: comment.url),
      Tag.tag(:meta, property: "og:description", content: comment.text),
      Tag.tag(:meta, property: "og:type", content: "website"),
      Tag.tag(:meta, property: "twitter:card", content: "summary")
    ]
  end

  def build_tags(%Comment{} = _comment, _locale), do: []
end
