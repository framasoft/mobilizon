defimpl Mobilizon.Service.Metadata, for: Mobilizon.Actors.Actor do
  alias Phoenix.HTML.Tag
  alias Mobilizon.Actors.Actor

  def build_tags(%Actor{} = actor) do
    [
      Tag.tag(:meta, property: "og:title", content: Actor.display_name_and_username(actor)),
      Tag.tag(:meta, property: "og:url", content: actor.url),
      Tag.tag(:meta, property: "og:description", content: actor.summary),
      Tag.tag(:meta, property: "og:type", content: "profile"),
      Tag.tag(:meta, property: "profile:username", content: actor.preferred_username),
      Tag.tag(:meta, property: "og:image", content: actor.avatar_url),
      Tag.tag(:meta, property: "twitter:card", content: "summary")
    ]
  end
end
