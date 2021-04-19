defmodule Mobilizon.Service.Metadata.Instance do
  @moduledoc """
  Generates metadata for every other page that isn't event/actor/comment
  """

  alias Phoenix.HTML
  alias Phoenix.HTML.Tag

  alias Mobilizon.Config
  alias Mobilizon.Service.Metadata.Utils
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes
  import Mobilizon.Web.Gettext

  @doc """
  Build the list of tags for the instance
  """
  @spec build_tags() :: list(Phoenix.HTML.safe())
  def build_tags do
    description = Utils.process_description(Config.instance_description())
    title = "#{Config.instance_name()} - Mobilizon"

    instance_json_ld = """
    <script type="application/ld+json">{
    "@context": "http://schema.org",
    "@type": "WebSite",
    "name": "#{title}",
    "url": "#{Endpoint.url()}",
    "potentialAction": {
    "@type": "SearchAction",
    "target": "#{Endpoint.url()}/search?term={search_term}",
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
    ] ++ maybe_add_instance_feeds(Config.get([:instance, :enable_instance_feeds]))
  end

  @spec maybe_add_instance_feeds(boolean()) :: list()
  defp maybe_add_instance_feeds(true) do
    [
      Tag.tag(:link,
        rel: "alternate",
        type: "application/atom+xml",
        title: gettext("%{name}'s feed", name: Config.instance_name()) |> HTML.raw(),
        href: Routes.feed_url(Endpoint, :instance, :atom)
      ),
      Tag.tag(:link,
        rel: "alternate",
        type: "text/calendar",
        title: gettext("%{name}'s feed", name: Config.instance_name()) |> HTML.raw(),
        href: Routes.feed_url(Endpoint, :instance, :ics)
      )
    ]
  end

  defp maybe_add_instance_feeds(false), do: []
end
