defmodule Mobilizon.Service.Notifications.SchedulerTest do
  @moduledoc """
  Test the scheduler module
  """

  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.Notifications.Scheduler
  alias Mobilizon.Service.Workers.Notification
  alias Mobilizon.Users.User

  use Mobilizon.DataCase

  import Mobilizon.Factory
  use Oban.Testing, repo: Mobilizon.Storage.Repo

  describe "Joining an event registers a job for notification before event" do
    test "if the user has allowed it" do
      %User{id: user_id} = user = insert(:user)
      settings = insert(:settings, user_id: user_id, notification_before_event: true)
      user = Map.put(user, :settings, settings)
      actor = insert(:actor, user: user)

      %Participant{id: participant_id, event: %Event{begins_on: begins_on}} =
        participant = insert(:participant, actor: actor)

      Scheduler.before_event_notification(participant)

      scheduled_at = DateTime.add(begins_on, -3600, :second)

      assert_enqueued(
        worker: Notification,
        args: %{participant_id: participant_id, op: :before_event_notification},
        scheduled_at: scheduled_at
      )
    end

    test "not if the user hasn't allowed it" do
      %User{} = user = insert(:user)
      actor = insert(:actor, user: user)

      %Participant{id: participant_id} = participant = insert(:participant, actor: actor)

      Scheduler.before_event_notification(participant)

      refute_enqueued(
        worker: Notification,
        args: %{participant_id: participant_id, op: :before_event_notification}
      )
    end
  end

  describe "Joining an event registers a job for notification on the day of the event" do
    test "if the user has allowed it" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_on_day: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      actor = insert(:actor, user: user)

      %DateTime{} = tomorrow = DateTime.utc_now() |> DateTime.add(3600 * 24)
      begins_on = %{tomorrow | hour: 16, minute: 0, second: 0, microsecond: {0, 0}}

      %Event{begins_on: begins_on} = event = insert(:event, begins_on: begins_on)

      %Participant{} = participant = insert(:participant, actor: actor, event: event)

      Scheduler.on_day_notification(participant)

      assert_enqueued(
        worker: Notification,
        args: %{user_id: user_id, op: :on_day_notification},
        scheduled_at: %{DateTime.shift_zone!(begins_on, settings.timezone) | hour: 8}
      )
    end

    test "not if the user hasn't allowed it" do
      %User{id: user_id} = user = insert(:user)
      actor = insert(:actor, user: user)

      %Participant{} = participant = insert(:participant, actor: actor)

      Scheduler.on_day_notification(participant)

      refute_enqueued(
        worker: Notification,
        args: %{user_id: user_id, op: :on_day_notification}
      )
    end

    test "not if it's too late" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_on_day: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      actor = insert(:actor, user: user)

      %Event{} = event = insert(:event, begins_on: DateTime.add(DateTime.utc_now(), -3600))

      %Participant{} = participant = insert(:participant, actor: actor, event: event)

      Scheduler.on_day_notification(participant)

      refute_enqueued(
        worker: Notification,
        args: %{user_id: user_id, op: :on_day_notification}
      )
    end

    test "only once" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_on_day: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      actor = insert(:actor, user: user)

      %DateTime{} = tomorrow = DateTime.utc_now() |> DateTime.add(3600 * 24)
      begins_on = %{tomorrow | hour: 16, minute: 0, second: 0, microsecond: {0, 0}}

      %Event{begins_on: begins_on} = event = insert(:event, begins_on: begins_on)

      %Participant{} = participant = insert(:participant, actor: actor, event: event)

      Scheduler.on_day_notification(participant)

      assert_enqueued(
        worker: Notification,
        args: %{user_id: user_id, op: :on_day_notification},
        scheduled_at: %{DateTime.shift_zone!(begins_on, settings.timezone) | hour: 8}
      )

      %DateTime{} = tomorrow = DateTime.utc_now() |> DateTime.add(3600 * 24)
      begins_on = %{tomorrow | hour: 19, minute: 0, second: 0, microsecond: {0, 0}}

      %Event{} = event = insert(:event, begins_on: begins_on)

      %Participant{} = participant = insert(:participant, actor: actor, event: event)

      Scheduler.on_day_notification(participant)
    end
  end
end
