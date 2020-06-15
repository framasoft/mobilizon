defimpl Mobilizon.Service.Metadata, for: Mobilizon.Actors.Actor do
  alias Phoenix.HTML.Tag
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Web.MediaProxy

  def build_tags(%Actor{} = actor, _locale \\ "en") do
    tags = [
      Tag.tag(:meta, property: "og:title", content: Actor.display_name_and_username(actor)),
      Tag.tag(:meta, property: "og:url", content: actor.url),
      Tag.tag(:meta, property: "og:description", content: actor.summary),
      Tag.tag(:meta, property: "og:type", content: "profile"),
      Tag.tag(:meta, property: "profile:username", content: actor.preferred_username),
      Tag.tag(:meta, property: "twitter:card", content: "summary")
    ]

    if is_nil(actor.avatar) do
      tags
    else
      tags ++
        [Tag.tag(:meta, property: "og:image", content: actor.avatar.url |> MediaProxy.url())]
    end
  end
end
