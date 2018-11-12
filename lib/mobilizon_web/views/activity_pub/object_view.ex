defmodule MobilizonWeb.ActivityPub.ObjectView do
  use MobilizonWeb, :view
  alias MobilizonWeb.ActivityPub.ObjectView
  alias Mobilizon.Service.ActivityPub.Utils

  def render("event.json", %{event: event}) do
    event = %{
      "type" => "Event",
      "actor" => event["actor"],
      "id" => event["id"],
      "name" => event["title"],
      "category" => render_one(event["category"], ObjectView, "category.json", as: :category),
      "content" => event["summary"],
      "mediaType" => "text/html"
      # "published" => Timex.format!(event.inserted_at, "{ISO:Extended}"),
      # "updated" => Timex.format!(event.updated_at, "{ISO:Extended}")
    }

    Map.merge(event, Utils.make_json_ld_header())
  end

  def render("comment.json", %{comment: comment}) do
    comment = %{
      "actor" => comment["actor"],
      "uuid" => comment["uuid"],
      # The activity should have attributedTo, not the comment itself
      #      "attributedTo" => comment.attributed_to,
      "type" => "Note",
      "id" => comment["id"],
      "content" => comment["content"],
      "mediaType" => "text/html"
      # "published" => Timex.format!(comment.inserted_at, "{ISO:Extended}"),
      # "updated" => Timex.format!(comment.updated_at, "{ISO:Extended}")
    }

    Map.merge(comment, Utils.make_json_ld_header())
  end

  def render("category.json", %{category: category}) when not is_nil(category) do
    %{
      "identifier" => category.id,
      "name" => category.title
    }
  end

  def render("category.json", %{category: _category}) do
    nil
  end
end
