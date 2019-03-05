defimpl Mobilizon.Service.Metadata, for: Mobilizon.Events.Event do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Events.Event
  alias MobilizonWeb.JsonLD.ObjectView

  def build_tags(%Event{} = event) do
    event
    |> do_build_tags()
    |> Enum.map(&HTML.safe_to_string/1)
    |> Enum.reduce("", fn tag, acc -> acc <> tag end)
    |> Kernel.<>(build_json_ld_schema(event))
  end

  # Build OpenGraph & Twitter Tags
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

  # Insert JSON-LD schema by hand because Tag.content_tag wants to escape it
  defp build_json_ld_schema(%Event{} = event) do
    "<script type=\"application\/ld+json\">" <>
      (ObjectView.render("event.json", %{event: event})
       |> Jason.encode!()) <> "</script>"
  end
end
