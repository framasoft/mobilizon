defmodule Mobilizon.Service.Workers.EventDelayedNotificationWorkerTest do
  @moduledoc """
  Test the event delayed notification worker
  """

  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Workers.EventDelayedNotificationWorker
  alias Oban.Job

  use Mobilizon.DataCase
  import Mobilizon.Factory

  test "Run notify of new event" do
    group = insert(:group)
    event = insert(:event, attributed_to: group)

    assert :ok ==
             EventDelayedNotificationWorker.perform(%Job{
               args: %{"action" => "notify_of_new_event", "event_uuid" => event.uuid}
             })
  end

  test "Run notify of updates to event" do
    group = insert(:group)
    event = insert(:event, attributed_to: group)
    old_event = %Event{event | title: "Previous title"}

    old_event =
      for {key, val} <- Map.from_struct(old_event), into: %{}, do: {Atom.to_string(key), val}

    changes = %{"title" => "New title"}

    assert {:ok, :ok} ==
             EventDelayedNotificationWorker.perform(%Job{
               args: %{
                 "action" => "notify_of_event_update",
                 "event_uuid" => event.uuid,
                 "old_event" => old_event,
                 "changes" => changes
               }
             })
  end
end
