defmodule Mobilizon.Service.Workers.EventDelayedNotificationWorker do
  @moduledoc """
  Worker to send notifications about an event changes a while after they're performed
  """

  use Oban.Worker, unique: [period: :infinity, keys: [:event_uuid, :action]]

  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Web.Email.Event, as: EventEmail
  alias Mobilizon.Web.Email.Group
  alias Oban.Job

  @impl Oban.Worker
  def perform(%Job{args: %{"action" => "notify_of_new_event", "event_uuid" => event_uuid}}) do
    case Events.get_event_by_uuid_with_preload(event_uuid) do
      %Event{} = event ->
        Group.notify_of_new_event(event)

      nil ->
        # Event deleted inbetween, no worries, just ignore
        :ok
    end
  end

  @impl Oban.Worker
  def perform(%Job{
        args: %{
          "action" => "notify_of_event_update",
          "event_uuid" => event_uuid,
          "old_event" => old_event,
          "changes" => changes
        }
      }) do
    old_event = for {key, val} <- old_event, into: %{}, do: {String.to_existing_atom(key), val}
    old_event = struct(Event, old_event)

    case Events.get_event_by_uuid_with_preload(event_uuid) do
      %Event{draft: false} = new_event ->
        EventEmail.calculate_event_diff_and_send_notifications(
          old_event,
          new_event,
          changes
        )

      _ ->
        # Event deleted inbetween, no worries, just ignore
        :ok
    end
  end
end
