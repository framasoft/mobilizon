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
      Tag.tag(:meta, property: "og:url", content: group.url),
      Tag.tag(:meta, property: "og:description", content: group.summary),
      Tag.tag(:meta, property: "og:type", content: "profile"),
      Tag.tag(:meta, property: "profile:username", content: group.preferred_username),
      Tag.tag(:meta, property: "twitter:card", content: "summary")
    ]
    |> maybe_add_avatar(group)
    |> add_group_schema(group)
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

  defp add_group_schema(tags, %Actor{} = group) do
    tags ++
      [
        ~s{<script type="application/ld+json">#{json(group)}</script>} |> HTML.raw(),
        Tag.tag(:link,
          rel: "alternate",
          type: "application/atom+xml",
          title:
            gettext("%{name}'s feed", name: group.name || group.preferred_username) |> HTML.raw(),
          href: Routes.feed_url(Endpoint, :actor, group.preferred_username, :atom)
        ),
        Tag.tag(:link,
          rel: "alternate",
          type: "text/calendar",
          title:
            gettext("%{name}'s feed", name: group.name || group.preferred_username) |> HTML.raw(),
          href: Routes.feed_url(Endpoint, :actor, group.preferred_username, :ics)
        )
      ]
  end

  # Insert JSON-LD schema by hand because Tag.content_tag wants to escape it
  defp json(%Actor{} = group) do
    "group.json"
    |> ObjectView.render(%{group: group})
    |> Jason.encode!()
  end
end
