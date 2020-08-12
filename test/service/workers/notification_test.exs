defmodule Mobilizon.Service.Workers.NotificationTest do
  @moduledoc """
  Test the scheduler module
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.Workers.Notification
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email.Notification, as: NotificationMailer

  use Mobilizon.DataCase
  use Bamboo.Test

  import Mobilizon.Factory

  describe "A before_event_notification job sends an email" do
    test "if the user is still participating" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings,
          user_id: user_id,
          notification_before_event: true
        )

      user = Map.put(user, :settings, settings)

      %Actor{} = actor = insert(:actor, user: user)

      %Participant{id: participant_id} =
        participant = insert(:participant, role: :participant, actor: actor)

      Notification.perform(%Oban.Job{
        args: %{"op" => "before_event_notification", "participant_id" => participant_id}
      })

      assert_delivered_email(
        NotificationMailer.before_event_notification(
          participant.actor.user.email,
          participant
        )
      )
    end

    test "unless the person is no longer participating" do
      %Event{id: event_id} = insert(:event)

      %User{} = user = insert(:user)
      %Actor{id: actor_id} = insert(:actor, user: user)

      {:ok, %Participant{id: participant_id} = participant} =
        Events.create_participant(%{actor_id: actor_id, event_id: event_id, role: :participant})

      actor = Map.put(participant.actor, :user, user)
      participant = Map.put(participant, :actor, actor)

      assert {:ok, %Participant{}} = Events.delete_participant(participant)

      Notification.perform(%Oban.Job{
        args: %{"op" => "before_event_notification", "participant_id" => participant_id}
      })

      refute_delivered_email(
        NotificationMailer.before_event_notification(
          participant.actor.user.email,
          participant
        )
      )
    end

    test "unless the event has been cancelled" do
      %Event{} = event = insert(:event, status: :cancelled)

      %Participant{id: participant_id} =
        participant = insert(:participant, role: :participant, event: event)

      Notification.perform(%Oban.Job{
        args: %{"op" => "before_event_notification", "participant_id" => participant_id}
      })

      refute_delivered_email(
        NotificationMailer.before_event_notification(
          participant.actor.user.email,
          participant
        )
      )
    end
  end

  describe "A on_day_notification job sends an email" do
    test "if the user is still participating" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_on_day: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      %Actor{} = actor = insert(:actor, user: user)

      %Participant{} = participant = insert(:participant, role: :participant, actor: actor)

      Notification.perform(%Oban.Job{
        args: %{"op" => "on_day_notification", "user_id" => user_id}
      })

      assert_delivered_email(
        NotificationMailer.on_day_notification(
          user,
          [participant],
          1
        )
      )
    end

    test "unless the person is no longer participating" do
      %Event{id: event_id} = insert(:event)

      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_on_day: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      %Actor{} = actor = insert(:actor, user: user)

      {:ok, %Participant{} = participant} =
        Events.create_participant(%{actor_id: actor.id, event_id: event_id, role: :participant})

      actor = Map.put(participant.actor, :user, user)
      participant = Map.put(participant, :actor, actor)

      assert {:ok, %Participant{}} = Events.delete_participant(participant)

      Notification.perform(%Oban.Job{
        args: %{"op" => "on_day_notification", "user_id" => user_id}
      })

      refute_delivered_email(
        NotificationMailer.on_day_notification(
          user,
          [participant],
          1
        )
      )
    end

    test "unless the event has been cancelled" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_on_day: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      %Actor{} = actor = insert(:actor, user: user)
      %Event{} = event = insert(:event, status: :cancelled)

      %Participant{} =
        participant = insert(:participant, role: :participant, event: event, actor: actor)

      Notification.perform(%Oban.Job{
        args: %{"op" => "on_day_notification", "user_id" => user_id}
      })

      refute_delivered_email(
        NotificationMailer.on_day_notification(
          user,
          [participant],
          1
        )
      )
    end

    test "with a lot of events" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_on_day: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      %Actor{} = actor = insert(:actor, user: user)

      participants =
        Enum.reduce(0..10, [], fn _i, acc ->
          %Participant{} = participant = insert(:participant, role: :participant, actor: actor)
          acc ++ [participant]
        end)

      Notification.perform(%Oban.Job{
        args: %{"op" => "on_day_notification", "user_id" => user_id}
      })

      refute_delivered_email(
        NotificationMailer.on_day_notification(
          user,
          participants,
          3
        )
      )
    end
  end

  describe "A weekly_notification job sends an email" do
    test "if the user is still participating" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_each_week: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      %Actor{} = actor = insert(:actor, user: user)

      %Participant{} = participant = insert(:participant, role: :participant, actor: actor)

      Notification.perform(%Oban.Job{
        args: %{"op" => "weekly_notification", "user_id" => user_id}
      })

      assert_delivered_email(
        NotificationMailer.weekly_notification(
          user,
          [participant],
          1
        )
      )
    end

    test "unless the person is no longer participating" do
      %Event{id: event_id} = insert(:event)

      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_each_week: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      %Actor{} = actor = insert(:actor, user: user)

      {:ok, %Participant{} = participant} =
        Events.create_participant(%{actor_id: actor.id, event_id: event_id, role: :participant})

      actor = Map.put(participant.actor, :user, user)
      participant = Map.put(participant, :actor, actor)

      assert {:ok, %Participant{}} = Events.delete_participant(participant)

      Notification.perform(%Oban.Job{
        args: %{"op" => "weekly_notification", "user_id" => user_id}
      })

      refute_delivered_email(
        NotificationMailer.weekly_notification(
          user,
          [participant],
          1
        )
      )
    end

    test "unless the event has been cancelled" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_each_week: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      %Actor{} = actor = insert(:actor, user: user)
      %Event{} = event = insert(:event, status: :cancelled)

      %Participant{} =
        participant = insert(:participant, role: :participant, event: event, actor: actor)

      Notification.perform(%Oban.Job{
        args: %{"op" => "weekly_notification", "user_id" => user_id}
      })

      refute_delivered_email(
        NotificationMailer.weekly_notification(
          user,
          [participant],
          1
        )
      )
    end

    test "with a lot of events" do
      %User{id: user_id} = user = insert(:user)

      settings =
        insert(:settings, user_id: user_id, notification_each_week: true, timezone: "Europe/Paris")

      user = Map.put(user, :settings, settings)
      %Actor{} = actor = insert(:actor, user: user)

      participants =
        Enum.reduce(0..10, [], fn _i, acc ->
          %Participant{} = participant = insert(:participant, role: :participant, actor: actor)
          acc ++ [participant]
        end)

      Notification.perform(%Oban.Job{
        args: %{"op" => "weekly_notification", "user_id" => user_id}
      })

      refute_delivered_email(
        NotificationMailer.weekly_notification(
          user,
          participants,
          3
        )
      )
    end
  end

  describe "A pending_participation_notification job sends an email" do
    test "if there are participants to approve" do
      %User{id: user_id} = user = insert(:user)

      %Event{id: event_id} = event = insert(:event)

      %Participant{} = insert(:participant, event: event, role: :not_approved)
      %Participant{} = insert(:participant, event: event, role: :not_approved)

      Notification.perform(%Oban.Job{
        args: %{
          "op" => "pending_participation_notification",
          "user_id" => user_id,
          "event_id" => event_id
        }
      })

      assert_delivered_email(
        NotificationMailer.pending_participation_notification(
          user,
          event,
          2
        )
      )
    end
  end
end
