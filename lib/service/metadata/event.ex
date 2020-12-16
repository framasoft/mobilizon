defimpl Mobilizon.Service.Metadata, for: Mobilizon.Events.Event do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Events.Event
  alias Mobilizon.Web.JsonLD.ObjectView
  import Mobilizon.Service.Metadata.Utils, only: [process_description: 2, strip_tags: 1]

  def build_tags(%Event{} = event, locale \\ "en") do
    event = Map.put(event, :description, process_description(event.description, locale))

    tags = [
      Tag.content_tag(:title, event.title <> " - Mobilizon"),
      Tag.tag(:meta, name: "description", content: event.description),
      Tag.tag(:meta, property: "og:title", content: event.title),
      Tag.tag(:meta, property: "og:url", content: event.url),
      Tag.tag(:meta, property: "og:description", content: event.description),
      Tag.tag(:meta, property: "og:type", content: "website"),
      # Tell Search Engines what's the origin
      Tag.tag(:link, rel: "canonical", href: event.url)
    ]

    tags =
      if is_nil(event.picture) do
        tags
      else
        tags ++
          [
            Tag.tag(:meta,
              property: "og:image",
              content: event.picture.file.url
            )
          ]
      end

    tags ++
      [
        Tag.tag(:meta, property: "twitter:card", content: "summary_large_image"),
        ~s{<script type="application/ld+json">#{json(event)}</script>} |> HTML.raw()
      ]
  end

  # Insert JSON-LD schema by hand because Tag.content_tag wants to escape it
  defp json(%Event{title: title} = event) do
    "event.json"
    |> ObjectView.render(%{event: %{event | title: strip_tags(title)}})
    |> Jason.encode!()
  end
end
