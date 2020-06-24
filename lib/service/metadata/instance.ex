defmodule Mobilizon.Service.Metadata.Instance do
  @moduledoc """
  Generates metadata for every other page that isn't event/actor/comment
  """

  alias Phoenix.HTML
  alias Phoenix.HTML.Tag

  alias Mobilizon.Config
  alias Mobilizon.Service.Formatter.HTML, as: HTMLFormatter
  alias Mobilizon.Web.Endpoint

  def build_tags do
    description = process_description(Config.instance_description())
    title = "#{Config.instance_name()} - Mobilizon"

    instance_json_ld = """
    <script type="application/ld+json">{
    "@context": "http://schema.org",
    "@type": "WebSite",
    "name": "#{title}",
    "url": "#{Endpoint.url()}",
    "potentialAction": {
    "@type": "SearchAction",
    "target": "#{Endpoint.url()}/search/{search_term}",
    "query-input": "required name=search_term"
    }
    }</script>
    """

    [
      Tag.content_tag(:title, title),
      Tag.tag(:meta, name: "description", content: description),
      Tag.tag(:meta, property: "og:title", content: title),
      Tag.tag(:meta, property: "og:url", content: Endpoint.url()),
      Tag.tag(:meta, property: "og:description", content: description),
      Tag.tag(:meta, property: "og:type", content: "website"),
      HTML.raw(instance_json_ld)
    ]
  end

  defp process_description(description) do
    description
    |> HTMLFormatter.strip_tags()
    |> String.slice(0..200)
    |> (&"#{&1}…").()
  end
end
