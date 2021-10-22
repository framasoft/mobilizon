defimpl Mobilizon.Service.Metadata, for: Mobilizon.Actors.Actor do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.JsonLD.ObjectView
  alias Mobilizon.Web.Router.Helpers, as: Routes
  import Mobilizon.Service.Metadata.Utils, only: [process_description: 2, default_description: 1]
  import Mobilizon.Web.Gettext

  def build_tags(_actor, _locale \\ "en")

  def build_tags(%Actor{type: :Group} = group, locale) do
    default_desc = default_description(locale)

    group =
      Map.update(group, :summary, default_desc, fn summary ->
        process_description(summary, locale)
      end)

    [
      Tag.tag(:meta, property: "og:title", content: Actor.display_name_and_username(group)),
      Tag.tag(:meta,
        property: "og:url",
        content:
          Endpoint
          |> Routes.page_url(
            :actor,
            Actor.preferred_username_and_domain(group)
          )
          |> URI.decode()
      ),
      Tag.tag(:meta, property: "og:description", content: group.summary),
      Tag.tag(:meta, property: "og:type", content: "profile"),
      Tag.tag(:meta,
        property: "profile:username",
        content: Actor.preferred_username_and_domain(group)
      ),
      Tag.tag(:meta, property: "twitter:card", content: "summary"),
      Tag.tag(:meta, property: "twitter:site", content: "@joinmobilizon")
    ]
    |> maybe_add_avatar(group)
    |> add_group_schema(group)
    |> add_group_feeds(group)
    |> add_canonical(group)
    |> maybe_add_no_index(group)
  end

  def build_tags(%Actor{} = _actor, _locale), do: []

  @spec maybe_add_avatar(list(Tag.t()), Actor.t()) :: list(Tag.t())
  defp maybe_add_avatar(tags, actor) do
    if is_nil(actor.avatar) do
      tags
    else
      tags ++
        [Tag.tag(:meta, property: "og:image", content: actor.avatar.url)]
    end
  end

  @spec add_group_schema(list(Tag.t()), Actor.t()) :: list(Tag.t())
  defp add_group_schema(tags, %Actor{} = group) do
    breadcrumbs = %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => [
        %{
          "@type" => "ListItem",
          "position" => 1,
          "name" => Actor.display_name(group)
        }
      ]
    }

    tags ++
      [
        ~s{<script type="application/ld+json">#{Jason.encode!(breadcrumbs)}</script>}
        |> HTML.raw(),
        ~s{<script type="application/ld+json">#{json(group)}</script>} |> HTML.raw()
      ]
  end

  @spec add_group_feeds(list(Tag.t()), Actor.t()) :: list(Tag.t())
  defp add_group_feeds(tags, %Actor{} = group) do
    tags ++
      [
        Tag.tag(:link,
          rel: "alternate",
          type: "application/atom+xml",
          title:
            gettext("%{name}'s feed", name: group.name || group.preferred_username) |> HTML.raw(),
          href:
            Routes.feed_url(Endpoint, :actor, Actor.preferred_username_and_domain(group), :atom)
        ),
        Tag.tag(:link,
          rel: "alternate",
          type: "text/calendar",
          title:
            gettext("%{name}'s feed", name: group.name || group.preferred_username) |> HTML.raw(),
          href:
            Routes.feed_url(
              Endpoint,
              :actor,
              Actor.preferred_username_and_domain(group),
              :ics
            )
        ),
        Tag.tag(:link,
          rel: "alternate",
          type: "application/activity+json",
          href: group.url
        )
      ]
  end

  @spec add_canonical(list(Tag.t()), Actor.t()) :: list(Tag.t())
  defp add_canonical(tags, %Actor{url: group_url}) do
    tags ++ [Tag.tag(:link, rel: "canonical", href: group_url)]
  end

  @spec maybe_add_no_index(list(Tag.t()), Actor.t()) :: list(Tag.t())
  defp maybe_add_no_index(tags, %Actor{domain: nil}), do: tags

  defp maybe_add_no_index(tags, %Actor{}) do
    tags ++ [Tag.tag(:meta, name: "robots", content: "noindex")]
  end

  # Insert JSON-LD schema by hand because Tag.content_tag wants to escape it
  defp json(%Actor{} = group) do
    "group.json"
    |> ObjectView.render(%{group: group})
    |> Jason.encode!()
  end
end
