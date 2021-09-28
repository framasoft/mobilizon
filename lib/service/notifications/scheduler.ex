defmodule Mobilizon.Service.Notifications.Scheduler do
  @moduledoc """
  Allows to insert jobs
  """

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.Workers.Notification
  alias Mobilizon.Users.{Setting, User}

  import Mobilizon.Service.DateTime,
    only: [
      datetime_tz_convert: 2,
      calculate_first_day_of_week: 2,
      calculate_next_day_notification: 2,
      calculate_next_week_notification: 2
    ]

  require Logger

  @spec trigger_notifications_for_participant(Participant.t()) :: {:ok, Oban.Job.t() | nil}
  def trigger_notifications_for_participant(%Participant{} = participant) do
    before_event_notification(participant)
    on_day_notification(participant)
    weekly_notification(participant)
    {:ok, nil}
  end

  @spec before_event_notification(Participant.t()) :: {:ok, nil}
  def before_event_notification(%Participant{
        id: participant_id,
        event: %Event{begins_on: begins_on},
        actor: %Actor{user_id: user_id}
      })
      when not is_nil(user_id) do
    case Users.get_setting(user_id) do
      %Setting{notification_before_event: true} ->
        Notification.enqueue(:before_event_notification, %{participant_id: participant_id},
          scheduled_at: DateTime.add(begins_on, -3600, :second)
        )

      _ ->
        {:ok, nil}
    end
  end

  def before_event_notification(_), do: {:ok, nil}

  @spec on_day_notification(Participant.t()) :: {:ok, Oban.Job.t() | nil | String.t()}
  def on_day_notification(%Participant{
        event: %Event{begins_on: begins_on},
        actor: %Actor{user_id: user_id}
      })
      when not is_nil(user_id) do
    case Users.get_setting(user_id) do
      %Setting{notification_on_day: true, timezone: timezone} ->
        %DateTime{hour: hour} = begins_on_shifted = datetime_tz_convert(begins_on, timezone)
        Logger.debug("Participation event start at #{inspect(begins_on_shifted)} (user timezone)")

        send_date =
          cond do
            DateTime.compare(begins_on, DateTime.utc_now()) == :lt ->
              nil

            hour > 8 ->
              # If the event is after 8 o'clock
              %{begins_on_shifted | hour: 8, minute: 0, second: 0, microsecond: {0, 0}}

            true ->
              # If the event is before 8 o'clock, we send the notification the day before,
              # unless this is already passed
              begins_on_shifted
              |> DateTime.add(-24 * 3_600)
              |> (&%{&1 | hour: 8, minute: 0, second: 0, microsecond: {0, 0}}).()
          end

        Logger.debug(
          "Participation notification should be sent at #{inspect(send_date)} (user timezone)"
        )

        if is_nil(send_date) or DateTime.compare(DateTime.utc_now(), send_date) == :gt do
          {:ok, "Too late to send same day notifications"}
        else
          Notification.enqueue(:on_day_notification, %{user_id: user_id}, scheduled_at: send_date)
        end

      _ ->
        {:ok, "User has disable on day notifications"}
    end
  end

  def on_day_notification(_), do: {:ok, nil}

  @spec weekly_notification(Participant.t()) :: {:ok, Oban.Job.t() | nil | String.t()}
  def weekly_notification(%Participant{
        event: %Event{begins_on: begins_on},
        actor: %Actor{user_id: user_id}
      })
      when not is_nil(user_id) do
    %User{settings: settings, locale: locale} = Users.get_user_with_settings!(user_id)

    case settings do
      %Setting{notification_each_week: true, timezone: timezone} ->
        %DateTime{} = begins_on_shifted = datetime_tz_convert(begins_on, timezone)

        Logger.debug(
          "Participation event start at #{inspect(begins_on_shifted)} (user timezone is #{timezone})"
        )

        notification_date =
          if Date.compare(begins_on, DateTime.utc_now()) == :gt do
            notification_day = calculate_first_day_of_week(DateTime.to_date(begins_on), locale)

            {:ok, %NaiveDateTime{} = notification_date} =
              notification_day |> NaiveDateTime.new(~T[08:00:00])

            # This is the datetime when the notification should be sent
            {:ok, %DateTime{} = notification_date} =
              DateTime.from_naive(notification_date, timezone)

            if Date.compare(notification_date, DateTime.utc_now()) == :gt do
              notification_date
            else
              nil
            end
          else
            nil
          end

        Logger.debug(
          "Participation notification should be sent at #{inspect(notification_date)} (user timezone)"
        )

        if is_nil(notification_date) do
          {:ok, "Too late to send weekly notifications"}
        else
          Notification.enqueue(:weekly_notification, %{user_id: user_id},
            scheduled_at: notification_date
          )
        end

      _ ->
        {:ok, "User has disabled weekly notifications"}
    end
  end

  def weekly_notification(_), do: {:ok, nil}

  @spec pending_participation_notification(Event.t(), Keyword.t()) :: {:ok, Oban.Job.t() | nil}
  def pending_participation_notification(event, options \\ [])

  def pending_participation_notification(
        %Event{
          id: event_id,
          organizer_actor_id: organizer_actor_id,
          local: true,
          begins_on: begins_on
        },
        options
      ) do
    with %Actor{user_id: user_id} when not is_nil(user_id) <-
           Actors.get_actor(organizer_actor_id),
         %User{
           locale: locale,
           settings: %Setting{
             notification_pending_participation: notification_pending_participation,
             timezone: timezone
           }
         } <- Users.get_user_with_settings!(user_id) do
      compare_to = Keyword.get(options, :compare_to, DateTime.utc_now())

      send_at =
        determine_send_at(notification_pending_participation, begins_on,
          compare_to: compare_to,
          timezone: timezone,
          locale: locale
        )

      params = %{
        user_id: user_id,
        event_id: event_id
      }

      cond do
        # Sending directly
        send_at == :direct ->
          Notification.enqueue(:pending_participation_notification, params)

        # Not sending
        is_nil(send_at) ->
          {:ok, nil}

        # Sending to calculated time
        DateTime.compare(begins_on, send_at) == :gt ->
          Notification.enqueue(:pending_participation_notification, params, scheduled_at: send_at)

        true ->
          {:ok, nil}
      end
    else
      _ -> {:ok, nil}
    end
  end

  def pending_participation_notification(_, _), do: {:ok, nil}

  def pending_membership_notification(%Actor{type: :Group, id: group_id}) do
    group_id
    |> Actors.list_all_administrator_members_for_group()
    |> Enum.map(fn %Member{actor: %Actor{id: actor_id}} ->
      Actors.get_actor(actor_id)
    end)
    |> Enum.each(fn actor -> pending_membership_admin_notification(actor, group_id) end)
  end

  def pending_membership_notification(_), do: {:ok, nil}

  defp pending_membership_admin_notification(%Actor{user_id: user_id}, group_id)
       when not is_nil(user_id) do
    case Users.get_user_with_settings!(user_id) do
      %User{} = user ->
        pending_membership_admin_notification_user(user, group_id)

      # No user for actor, probably a remote actor, ignore
      _ ->
        {:ok, nil}
    end
  end

  defp pending_membership_admin_notification_user(
         %User{
           id: user_id,
           settings: %Setting{
             notification_pending_membership: notification_pending_membership,
             timezone: timezone
           }
         },
         group_id
       ) do
    send_at =
      case notification_pending_membership do
        :none ->
          nil

        :direct ->
          :direct

        :one_day ->
          calculate_next_day_notification(Date.utc_today(), timezone)

        :one_hour ->
          DateTime.utc_now()
          |> DateTime.shift_zone!(timezone)
          |> (&%{&1 | minute: 0, second: 0, microsecond: {0, 0}}).()
      end

    params = %{
      user_id: user_id,
      group_id: group_id
    }

    cond do
      # Sending directly
      send_at == :direct ->
        Notification.enqueue(:pending_membership_notification, params)

      # Not sending
      is_nil(send_at) ->
        {:ok, nil}

      # Sending to calculated time
      true ->
        Notification.enqueue(:pending_membership_notification, params, scheduled_at: send_at)
    end
  end

  defp determine_send_at(notification_pending_participation, begins_on, options) do
    timezone = Keyword.get(options, :timezone, "Etc/UTC")
    locale = Keyword.get(options, :locale, "en")
    compare_to = Keyword.get(options, :compare_to, DateTime.utc_now())

    case notification_pending_participation do
      :none ->
        nil

      :direct ->
        :direct

      :one_day ->
        calculate_next_day_notification(DateTime.to_date(compare_to),
          timezone: timezone,
          compare_to: compare_to
        )

      :one_week ->
        calculate_next_week_notification(begins_on,
          timezone: timezone,
          locale: locale,
          compare_to: compare_to
        )

      :one_hour ->
        compare_to
        |> DateTime.shift_zone!(timezone)
        |> (&%{&1 | minute: 0, second: 0, microsecond: {0, 0}}).()
    end
  end
end
