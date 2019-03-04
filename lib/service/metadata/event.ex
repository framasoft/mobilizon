defimpl Mobilizon.Service.Metadata, for: Mobilizon.Events.Event do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Events.Event

  def build_tags(%Event{} = event) do
    event
    |> do_build_tags()
    |> Enum.map(&HTML.safe_to_string/1)
    |> Enum.reduce("", fn tag, acc -> acc <> tag end)
  end

  defp do_build_tags(%Event{} = event) do
    [
      Tag.tag(:meta, property: "og:title", content: event.title),
      Tag.tag(:meta, property: "og:url", content: event.url),
      Tag.tag(:meta, property: "og:description", content: event.description),
      Tag.tag(:meta, property: "og:type", content: "website"),
      Tag.tag(:meta, property: "og:image", content: event.thumbnail),
      Tag.tag(:meta, property: "og:image", content: event.large_image),
      Tag.tag(:meta, property: "twitter:card", content: "summary_large_image")
    ]
  end
end
