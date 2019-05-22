defimpl Mobilizon.Service.Metadata, for: Mobilizon.Events.Event do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Events.Event
  alias MobilizonWeb.JsonLD.ObjectView

  def build_tags(%Event{} = event) do
    tags = [
      Tag.tag(:meta, property: "og:title", content: event.title),
      Tag.tag(:meta, property: "og:url", content: event.url),
      Tag.tag(:meta, property: "og:description", content: event.description),
      Tag.tag(:meta, property: "og:type", content: "website")
    ]

    tags =
      if is_nil(event.picture) do
        tags
      else
        tags ++
          [
            Tag.tag(:meta, property: "og:image", content: event.picture.file.url)
          ]
      end

    tags ++
      [
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
