defimpl Mobilizon.Service.Metadata, for: Mobilizon.Events.Event do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.{Event, EventOptions}
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.JsonLD.ObjectView
  alias Mobilizon.Web.Router.Helpers, as: Routes

  import Mobilizon.Service.Metadata.Utils,
    only: [process_description: 2, strip_tags: 1, datetime_to_string: 2, render_address: 1]

  def build_tags(%Event{} = event, locale \\ "en") do
    formatted_description = description(event, locale)

    tags = [
      Tag.content_tag(:title, event.title <> " - Mobilizon"),
      Tag.tag(:meta, name: "description", content: process_description(event.description, locale)),
      Tag.tag(:meta, property: "og:title", content: event.title),
      Tag.tag(:meta, property: "og:url", content: event.url),
      Tag.tag(:meta, property: "og:description", content: formatted_description),
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

    breadcrumbs =
      if event.attributed_to do
        [
          %{
            "@context" => "https://schema.org",
            "@type" => "BreadcrumbList",
            "itemListElement" => [
              %{
                "@type" => "ListItem",
                "position" => 1,
                "name" => Actor.display_name(event.attributed_to),
                "item" =>
                  Endpoint
                  |> Routes.page_url(
                    :actor,
                    Actor.preferred_username_and_domain(event.attributed_to)
                  )
                  |> URI.decode()
              },
              %{
                "@type" => "ListItem",
                "position" => 2,
                "name" => event.title
              }
            ]
          }
        ]
      else
        []
      end

    breadcrumbs =
      breadcrumbs ++
        [
          %{
            "@context" => "https://schema.org",
            "@type" => "BreadcrumbList",
            "itemListElement" => [
              %{
                "@type" => "ListItem",
                "position" => 1,
                "name" => "Events",
                "item" => "#{Endpoint.url()}/search"
              },
              %{
                "@type" => "ListItem",
                "position" => 2,
                "name" => event.title
              }
            ]
          }
        ]

    tags ++
      [
        Tag.tag(:meta, property: "twitter:card", content: "summary_large_image"),
        ~s{<script type="application/ld+json">#{Jason.encode!(breadcrumbs)}</script>}
        |> HTML.raw(),
        ~s{<script type="application/ld+json">#{json(event)}</script>} |> HTML.raw()
      ]
  end

  # Insert JSON-LD schema by hand because Tag.content_tag wants to escape it
  defp json(%Event{title: title} = event) do
    "event.json"
    |> ObjectView.render(%{event: %{event | title: strip_tags(title)}})
    |> Jason.encode!()
  end

  defp description(
         %Event{
           description: description,
           begins_on: begins_on,
           physical_address: address,
           options: %EventOptions{timezone: timezone},
           language: language
         },
         locale
       ) do
    language = build_language(language, locale)
    begins_on = build_begins_on(begins_on, timezone)

    begins_on
    |> datetime_to_string(language)
    |> (&[&1]).()
    |> add_timezone(begins_on)
    |> maybe_build_address(address)
    |> build_description(description, language)
    |> Enum.join(" - ")
  end

  @spec build_language(String.t() | nil, String.t()) :: String.t()
  defp build_language(language, locale), do: language || locale

  @spec build_begins_on(DateTime.t(), String.t() | nil) :: DateTime.t()
  defp build_begins_on(begins_on, timezone) do
    if timezone do
      case DateTime.shift_zone(begins_on, timezone) do
        {:ok, begins_on} -> begins_on
        {:error, _err} -> begins_on
      end
    else
      begins_on
    end
  end

  defp add_timezone(elements, %DateTime{} = begins_on) do
    elements ++ [Cldr.DateTime.Formatter.zone_gmt(begins_on)]
  end

  @spec maybe_build_address(list(String.t()), Address.t() | nil) :: list(String.t())
  defp maybe_build_address(elements, %Address{} = address) do
    elements ++ [render_address(address)]
  end

  defp maybe_build_address(elements, _address), do: elements

  @spec build_description(list(String.t()), String.t(), String.t()) :: list(String.t())
  defp build_description(elements, description, language) do
    elements ++ [process_description(description, language)]
  end
end
