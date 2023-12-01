defmodule Mobilizon.Service.Metadata.Instance do
  @moduledoc """
  Generates metadata for every other page that isn't event/actor/comment
  """

  alias Phoenix.HTML
  alias Phoenix.HTML.Tag

  alias Mobilizon.Config
  alias Mobilizon.Service.Metadata.Utils
  alias Mobilizon.Web.Endpoint
  use Mobilizon.Web, :verified_routes
  import Mobilizon.Web.Gettext

  @doc """
  Build the list of tags for the instance
  """
  @spec build_tags() :: list(Phoenix.HTML.safe())
  def build_tags do
    description = Utils.process_description(Config.instance_description())
    title = "#{Config.instance_name()} - Mobilizon"

    json_ld = %{
      "@context" => "http://schema.org",
      "@type" => "WebSite",
      "name" => "#{title}",
      "url" => "#{Endpoint.url()}",
      "potentialAction" => %{
        "@type" => "SearchAction",
        "target" => "#{Endpoint.url()}/search?term={search_term}",
        "query-input" => "required name=search_term"
      }
    }

    instance_json_ld = """
    <script type="application/ld+json">#{Jason.encode!(json_ld)}</script>
    """

    [
      Tag.content_tag(:title, title),
      Tag.tag(:meta, name: "description", content: description),
      Tag.tag(:meta, property: "og:title", content: title),
      Tag.tag(:meta, property: "og:url", content: Endpoint.url()),
      Tag.tag(:meta, property: "og:description", content: description),
      Tag.tag(:meta, property: "og:type", content: "website"),
      HTML.raw(instance_json_ld)
    ] ++ maybe_add_instance_feeds(enable_instance_feeds())
  end

  defp enable_instance_feeds do
    get_in(Application.get_env(:mobilizon, :instance), [:enable_instance_feeds])
  end

  @spec maybe_add_instance_feeds(boolean()) :: list()
  defp maybe_add_instance_feeds(true) do
    [
      Tag.tag(:link,
        rel: "alternate",
        type: "application/atom+xml",
        title: gettext("%{name}'s feed", name: Config.instance_name()) |> HTML.raw(),
        href: url(~p"/feed/instance/atom")
      ),
      Tag.tag(:link,
        rel: "alternate",
        type: "text/calendar",
        title: gettext("%{name}'s feed", name: Config.instance_name()) |> HTML.raw(),
        href: url(~p"/feed/instance/ics")
      )
    ]
  end

  defp maybe_add_instance_feeds(false), do: []
end
