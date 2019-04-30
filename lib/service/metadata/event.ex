defimpl Mobilizon.Service.Metadata, for: Mobilizon.Events.Event do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Events.Event
  alias MobilizonWeb.JsonLD.ObjectView

  def build_tags(%Event{} = event) do
    [
      Tag.tag(:meta, property: "og:title", content: event.title),
      Tag.tag(:meta, property: "og:url", content: event.url),
      Tag.tag(:meta, property: "og:description", content: event.description),
      Tag.tag(:meta, property: "og:type", content: "website"),
      Tag.tag(:meta, property: "og:image", content: event.thumbnail),
      Tag.tag(:meta, property: "og:image", content: event.large_image),
      Tag.tag(:meta, property: "twitter:card", content: "summary_large_image"),
      ~s{<script type="application/ld+json">#{json(event)}</script>} |> HTML.raw()
    ]
  end

  # Insert JSON-LD schema by hand because Tag.content_tag wants to escape it
  defp json(%Event{} = event) do
    "event.json"
    |> ObjectView.render(%{event: event})
    |> Jason.encode!()
  end
end
