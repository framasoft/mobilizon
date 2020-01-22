defmodule MobilizonWeb.ActivityPub.ObjectView do
  use MobilizonWeb, :view

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
