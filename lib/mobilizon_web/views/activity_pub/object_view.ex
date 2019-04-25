defmodule MobilizonWeb.ActivityPub.ObjectView do
  use MobilizonWeb, :view
  alias Mobilizon.Service.ActivityPub.Utils
  alias Mobilizon.Activity

  def render("event.json", %{event: event}) do
    {:ok, html, []} = Earmark.as_html(event["summary"])

    event = %{
      "type" => "Event",
      "attributedTo" => event["actor"],
      "id" => event["id"],
      "name" => event["title"],
      "category" => event["category"],
      "content" => html,
      "source" => %{
        "content" => event["summary"],
        "mediaType" => "text/markdown"
      },
      "mediaType" => "text/html",
      "published" => event["publish_at"],
      "updated" => event["updated_at"]
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

  def render("activity.json", %{activity: %Activity{local: local, data: data} = activity}) do
    %{
      "id" => data["id"],
      "type" =>
        if local do
          "Create"
        else
          "Announce"
        end,
      "actor" => activity.actor,
      # Not sure if needed since this is used into outbox
      "published" => Timex.now(),
      "to" => activity.recipients,
      "object" =>
        case data["type"] do
          "Event" ->
            render_one(data, ObjectView, "event.json", as: :event)

          "Note" ->
            render_one(data, ObjectView, "comment.json", as: :comment)
        end
    }
    |> Map.merge(Utils.make_json_ld_header())
  end
end
