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

  describe "Joining an event registers a job for notification on week of the event" do
    test "if the user has allowed it" do
      %User{id: user_id} = user = insert(:user, locale: "fr")

      settings =
        insert(:settings, user_id: user_id, notification_each_week: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      actor = insert(:actor, user: user)

      # Make sure event happens next week
      %Date{} = event_day = Date.utc_today() |> Date.add(7)
      {:ok, %NaiveDateTime{} = event_date} = event_day |> NaiveDateTime.new(~T[16:00:00])
      {:ok, begins_on} = DateTime.from_naive(event_date, "Etc/UTC")

      %Event{} = event = insert(:event, begins_on: begins_on)

      %Participant{} = participant = insert(:participant, actor: actor, event: event)

      Scheduler.weekly_notification(participant)

      {:ok, scheduled_at} =
        begins_on
        |> DateTime.to_date()
        |> calculate_first_day_of_week("fr")
        |> NaiveDateTime.new(~T[08:00:00])

      {:ok, scheduled_at} = DateTime.from_naive(scheduled_at, "Europe/Paris")

      assert_enqueued(
        worker: Notification,
        args: %{user_id: user_id, op: :weekly_notification},
        scheduled_at: scheduled_at
      )
    end

    test "not if the user hasn't allowed it" do
      %User{id: user_id} = user = insert(:user)
      actor = insert(:actor, user: user)

      %Participant{} = participant = insert(:participant, actor: actor)

      Scheduler.weekly_notification(participant)

      refute_enqueued(
        worker: Notification,
        args: %{user_id: user_id, op: :weekly_notification}
      )
    end

    test "not if it's too late" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_on_day: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      actor = insert(:actor, user: user)

      {:ok, begins_on} =
        Date.utc_today()
        |> calculate_first_day_of_week("fr")
        |> NaiveDateTime.new(~T[05:00:00])

      {:ok, begins_on} = DateTime.from_naive(begins_on, "Europe/Paris")

      %Event{} = event = insert(:event, begins_on: begins_on)

      %Participant{} = participant = insert(:participant, actor: actor, event: event)

      Scheduler.weekly_notification(participant)

      refute_enqueued(
        worker: Notification,
        args: %{user_id: user_id, op: :weekly_notification}
      )
    end
  end

  describe "Asking to participate registers a job for notification" do
    test "if the user has allowed it" do
      %User{id: user_id} = user = insert(:user, locale: "fr")

      settings =
        insert(:settings,
          user_id: user_id,
          notification_pending_participation: :one_day,
          timezone: "Europe/Paris"
        )

      user = Map.put(user, :settings, settings)
      actor = insert(:actor, user: user)

      # Make sure event happens next week
      %Date{} = event_day = Date.utc_today() |> Date.add(3)
      {:ok, %NaiveDateTime{} = event_date} = event_day |> NaiveDateTime.new(~T[16:00:00])
      {:ok, begins_on} = DateTime.from_naive(event_date, "Etc/UTC")

      %Event{} = event = insert(:event, begins_on: begins_on, local: true, organizer_actor: actor)

      %Participant{} = _participant = insert(:participant, event: event, role: :not_approved)

      Scheduler.pending_participation_notification(event)

      now = Time.utc_now()

      {:ok, scheduled_at} =
        if now.hour <= 18 do
          NaiveDateTime.new(Date.utc_today(), ~T[18:00:00])
        else
          Date.utc_today() |> Date.add(1) |> NaiveDateTime.new(~T[18:00:00])
        end

      {:ok, scheduled_at} = DateTime.from_naive(scheduled_at, "Europe/Paris")

      assert_enqueued(
        worker: Notification,
        args: %{user_id: user_id, event_id: event.id, op: :pending_participation_notification},
        scheduled_at: scheduled_at
      )
    end

    test "not if the user hasn't allowed it" do
      %User{id: user_id} = user = insert(:user)
      actor = insert(:actor, user: user)

      %Participant{} = insert(:participant)

      %Event{} = event = insert(:event, local: true, organizer_actor: actor)

      Scheduler.pending_participation_notification(event)

      refute_enqueued(
        worker: Notification,
        args: %{user_id: user_id, event_id: event.id, op: :pending_participation_notification}
      )
    end

    test "right away if the user has allowed it" do
      %User{id: user_id} = user = insert(:user, locale: "fr")

      settings =
        insert(:settings,
          user_id: user_id,
          notification_pending_participation: :direct,
          timezone: "Europe/Paris"
        )

      user = Map.put(user, :settings, settings)
      actor = insert(:actor, user: user)

      # Make sure event happens next week
      %Date{} = event_day = Date.utc_today() |> Date.add(3)
      {:ok, %NaiveDateTime{} = event_date} = event_day |> NaiveDateTime.new(~T[16:00:00])
      {:ok, begins_on} = DateTime.from_naive(event_date, "Etc/UTC")

      %Event{} = event = insert(:event, begins_on: begins_on, local: true, organizer_actor: actor)

      %Participant{} = _participant = insert(:participant, event: event, role: :not_approved)

      Scheduler.pending_participation_notification(event)

      assert_enqueued(
        worker: Notification,
        args: %{user_id: user_id, event_id: event.id, op: :pending_participation_notification}
      )
    end

    test "every hour" do
      %User{id: user_id} = user = insert(:user, locale: "fr")

      settings =
        insert(:settings,
          user_id: user_id,
          notification_pending_participation: :one_hour,
          timezone: "Europe/Paris"
        )

      user = Map.put(user, :settings, settings)
      actor = insert(:actor, user: user)

      # Make sure event happens next week
      %Date{} = event_day = Date.utc_today() |> Date.add(3)
      {:ok, %NaiveDateTime{} = event_date} = event_day |> NaiveDateTime.new(~T[16:00:00])
      {:ok, begins_on} = DateTime.from_naive(event_date, "Etc/UTC")

      %Event{} = event = insert(:event, begins_on: begins_on, local: true, organizer_actor: actor)

      %Participant{} = _participant = insert(:participant, event: event, role: :not_approved)

      Scheduler.pending_participation_notification(event)

      scheduled_at =
        DateTime.utc_now()
        |> DateTime.shift_zone!("Europe/Paris")
        |> (&%{&1 | minute: 0, second: 0, microsecond: {0, 0}}).()

      assert_enqueued(
        worker: Notification,
        args: %{user_id: user_id, event_id: event.id, op: :pending_participation_notification},
        scheduled_at: scheduled_at
      )
    end
  end

  defp calculate_first_day_of_week(%Date{} = date, locale) do
    day_number = Date.day_of_week(date)
    first_day_number = Cldr.Calendar.first_day_for_locale(locale)

    if day_number == first_day_number,
      do: date,
      else: calculate_first_day_of_week(Date.add(date, -1), locale)
  end
end
