defimpl Mobilizon.Service.Metadata, for: Mobilizon.Events.Comment do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Events.Comment

  def build_tags(%Comment{} = comment) do
    comment
    |> do_build_tags()
    |> Enum.map(&HTML.safe_to_string/1)
    |> Enum.reduce("", fn tag, acc -> acc <> tag end)
  end

  defp do_build_tags(%Comment{} = comment) do
    [
      Tag.tag(:meta, property: "og:title", content: comment.actor.preferred_username),
      Tag.tag(:meta, property: "og:url", content: comment.url),
      Tag.tag(:meta, property: "og:description", content: comment.text),
      Tag.tag(:meta, property: "og:type", content: "website"),
      Tag.tag(:meta, property: "twitter:card", content: "summary")
    ]
  end
end
