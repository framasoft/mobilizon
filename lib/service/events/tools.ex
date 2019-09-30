defmodule Mobilizon.Service.Events.Tool do
  @moduledoc """
  Event-related tools
  """
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User
  alias MobilizonWeb.Email
  alias Mobilizon.Storage.Repo

  @important_changes [:title, :begins_on, :ends_on]

  def calculate_event_diff_and_send_notifications(
        %Event{} = old_event,
        %Event{id: event_id} = event,
        changes
      ) do
    important = MapSet.new(@important_changes)

    diff =
      changes
      |> Map.keys()
      |> MapSet.new()
      |> MapSet.intersection(important)

    if MapSet.size(diff) > 0 do
      Repo.transaction(fn ->
        event_id
        |> Events.list_local_emails_user_participants_for_event_query()
        |> Repo.stream()
        |> Enum.to_list()
        |> Enum.each(
          &send_notification_for_event_update_to_participant(&1, old_event, event, diff)
        )
      end)
    end
  end

  defp send_notification_for_event_update_to_participant(
         {%Actor{} = actor, %User{} = user},
         %Event{} = old_event,
         %Event{} = event,
         diff
       ) do
    user
    |> Email.Event.event_updated(actor, old_event, event, diff)
    |> Email.Mailer.deliver_later()
  end
end
