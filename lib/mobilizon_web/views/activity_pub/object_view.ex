defmodule MobilizonWeb.ActivityPub.ObjectView do
  use MobilizonWeb, :view
  alias MobilizonWeb.ActivityPub.ObjectView
  alias Mobilizon.Service.ActivityPub.Transmogrifier
  alias Mobilizon.Service.ActivityPub.Utils

  def render("event.json", %{event: event}) do
    event = %{
      "type" => "Event",
      "id" => event.url,
      "name" => event.title,
      "category" => render_one(event.category, ObjectView, "category.json", as: :category),
      "content" => event.description,
      "mediaType" => "text/html",
      "published" => Timex.format!(event.inserted_at, "{ISO:Extended}"),
      "updated" => Timex.format!(event.updated_at, "{ISO:Extended}")
    }

    Map.merge(event, Utils.make_json_ld_header())
  end

  def render("comment.json", %{comment: comment}) do
    event = %{
      "type" => "Note",
      "id" => comment.url,
      "content" => comment.text,
      "mediaType" => "text/html",
      "published" => Timex.format!(comment.inserted_at, "{ISO:Extended}"),
      "updated" => Timex.format!(comment.updated_at, "{ISO:Extended}")
    }

    Map.merge(event, Utils.make_json_ld_header())
  end

  def render("category.json", %{category: category}) do
    %{"title" => category.title}
  end

  def render("category.json", %{category: nil}) do
    nil
  end
end
