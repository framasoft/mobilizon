defimpl Mobilizon.Service.Metadata, for: Mobilizon.Conversations.Comment do
  alias Phoenix.HTML.Tag
  alias Mobilizon.Conversations.Comment

  def build_tags(%Comment{} = comment) do
    [
      Tag.tag(:meta, property: "og:title", content: comment.actor.preferred_username),
      Tag.tag(:meta, property: "og:url", content: comment.url),
      Tag.tag(:meta, property: "og:description", content: comment.text),
      Tag.tag(:meta, property: "og:type", content: "website"),
      Tag.tag(:meta, property: "twitter:card", content: "summary")
    ]
  end
end
