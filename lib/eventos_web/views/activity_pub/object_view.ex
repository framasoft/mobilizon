defmodule EventosWeb.ActivityPub.ObjectView do
  use EventosWeb, :view
  alias Eventos.Service.ActivityPub.Transmogrifier
  @base %{
    "@context" => [
      "https://www.w3.org/ns/activitystreams",
      "https://w3id.org/security/v1",
      %{
        "manuallyApprovesFollowers" => "as:manuallyApprovesFollowers",
        "sensitive" => "as:sensitive",
        "Hashtag" => "as:Hashtag",
        "toot" => "http://joinmastodon.org/ns#",
        "Emoji" => "toot:Emoji"
      }
    ]
  }

  def render("event.json", %{event: event}) do


    event = %{
      "type" => "Event",
      "id" => event.url,
      "name" => event.title,
      "category" => %{"title" => event.category.title},
      "content" => event.description,
      "mediaType" => "text/markdown",
      "published" => Timex.format!(event.inserted_at, "{ISO:Extended}"),
      "updated" => Timex.format!(event.updated_at, "{ISO:Extended}"),
    }
    Map.merge(event, @base)
  end

  def render("category.json", %{category: category}) do
    category
  end
end
