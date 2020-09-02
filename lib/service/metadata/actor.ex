defimpl Mobilizon.Service.Metadata, for: Mobilizon.Actors.Actor do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Web.JsonLD.ObjectView
  alias Mobilizon.Web.MediaProxy

  def build_tags(%Actor{} = actor, _locale \\ "en") do
    [
      Tag.tag(:meta, property: "og:title", content: Actor.display_name_and_username(actor)),
      Tag.tag(:meta, property: "og:url", content: actor.url),
      Tag.tag(:meta, property: "og:description", content: actor.summary),
      Tag.tag(:meta, property: "og:type", content: "profile"),
      Tag.tag(:meta, property: "profile:username", content: actor.preferred_username),
      Tag.tag(:meta, property: "twitter:card", content: "summary")
    ]
    |> maybe_add_avatar(actor)
    |> maybe_add_group_schema(actor)
  end

  @spec maybe_add_avatar(list(Tag.t()), Actor.t()) :: list(Tag.t())
  defp maybe_add_avatar(tags, actor) do
    if is_nil(actor.avatar) do
      tags
    else
      tags ++
        [Tag.tag(:meta, property: "og:image", content: actor.avatar.url |> MediaProxy.url())]
    end
  end

  defp maybe_add_group_schema(tags, %Actor{type: :Group} = group) do
    tags ++ [~s{<script type="application/ld+json">#{json(group)}</script>} |> HTML.raw()]
  end

  defp maybe_add_group_schema(tags, _), do: tags

  # Insert JSON-LD schema by hand because Tag.content_tag wants to escape it
  defp json(%Actor{} = group) do
    "group.json"
    |> ObjectView.render(%{group: group})
    |> Jason.encode!()
  end
end
