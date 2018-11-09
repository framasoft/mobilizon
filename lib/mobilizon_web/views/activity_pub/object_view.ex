defmodule MobilizonWeb.ActivityPub.ObjectView do
  use MobilizonWeb, :view
  alias MobilizonWeb.ActivityPub.ObjectView
  alias Mobilizon.Service.ActivityPub.Transmogrifier

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
      "category" => render_one(event.category, ObjectView, "category.json", as: :category),
      "content" => event.description,
      "mediaType" => "text/markdown",
      "published" => Timex.format!(event.inserted_at, "{ISO:Extended}"),
      "updated" => Timex.format!(event.updated_at, "{ISO:Extended}")
    }

    Map.merge(event, @base)
  end

  def render("comment.json", %{comment: comment}) do
    event = %{
      "type" => "Note",
      "id" => comment.url,
      "content" => comment.text,
      "mediaType" => "text/markdown",
      "published" => Timex.format!(comment.inserted_at, "{ISO:Extended}"),
      "updated" => Timex.format!(comment.updated_at, "{ISO:Extended}")
    }

    Map.merge(event, @base)
  end

  def render("category.json", %{category: category}) do
    %{"title" => category.title}
  end

  def render("category.json", %{category: nil}) do
    nil
  end
end
