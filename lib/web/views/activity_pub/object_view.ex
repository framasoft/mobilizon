defmodule Mobilizon.Web.ActivityPub.ObjectView do
  use Mobilizon.Web, :view

  alias Mobilizon.Federation.ActivityPub.{Activity, Utils}

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
      "published" => DateTime.utc_now() |> DateTime.to_iso8601(),
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
