defmodule Mobilizon.Service.Notifications.Scheduler do
  @moduledoc """
  Allows to insert jobs
  """

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.Workers.Notification
  alias Mobilizon.Users.{Setting, User}
  require Logger

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

  def on_day_notification(%Participant{
        event: %Event{begins_on: begins_on},
        actor: %Actor{user_id: user_id}
      })
      when not is_nil(user_id) do
    case Users.get_setting(user_id) do
      %Setting{notification_on_day: true, timezone: timezone} ->
        %DateTime{hour: hour} = begins_on_shifted = shift_zone(begins_on, timezone)
        Logger.debug("Participation event start at #{inspect(begins_on_shifted)} (user timezone)")

        send_date =
          cond do
            begins_on < DateTime.utc_now() ->
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

        if DateTime.utc_now() > send_date do
          {:ok, "Too late to send same day notifications"}
        else
          Notification.enqueue(:on_day_notification, %{user_id: user_id}, scheduled_at: send_date)
        end

      _ ->
        {:ok, "User has disable on day notifications"}
    end
  end

  def on_day_notification(_), do: {:ok, nil}

  def weekly_notification(%Participant{
        event: %Event{begins_on: begins_on},
        actor: %Actor{user_id: user_id}
      })
      when not is_nil(user_id) do
    %User{settings: settings, locale: locale} = Users.get_user_with_settings!(user_id)

    case settings do
      %Setting{notification_each_week: true, timezone: timezone} ->
        %DateTime{} = begins_on_shifted = shift_zone(begins_on, timezone)

        Logger.debug(
          "Participation event start at #{inspect(begins_on_shifted)} (user timezone is #{
            timezone
          })"
        )

        notification_date =
          unless begins_on < DateTime.utc_now() do
            notification_day = calculate_first_day_of_week(DateTime.to_date(begins_on), locale)

            {:ok, %NaiveDateTime{} = notification_date} =
              notification_day |> NaiveDateTime.new(~T[08:00:00])

            # This is the datetime when the notification should be sent
            {:ok, %DateTime{} = notification_date} =
              DateTime.from_naive(notification_date, timezone)

            unless notification_date < DateTime.utc_now() do
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

  def pending_participation_notification(%Event{
        id: event_id,
        organizer_actor_id: organizer_actor_id,
        local: true
      }) do
    with %Actor{user_id: user_id} when not is_nil(user_id) <-
           Actors.get_actor(organizer_actor_id),
         %User{
           settings: %Setting{
             notification_pending_participation: notification_pending_participation,
             timezone: timezone
           }
         } <- Users.get_user_with_settings!(user_id) do
      send_at =
        case notification_pending_participation do
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
        true ->
          Notification.enqueue(:pending_participation_notification, params, scheduled_at: send_at)
      end
    else
      _ -> {:ok, nil}
    end
  end

  def pending_participation_notification(_), do: {:ok, nil}

  defp shift_zone(datetime, timezone) do
    case DateTime.shift_zone(datetime, timezone) do
      {:ok, shift_datetime} -> shift_datetime
      {:error, _} -> datetime
    end
  end

  defp calculate_first_day_of_week(%Date{} = date, locale) do
    day_number = Date.day_of_week(date)
    first_day_number = Cldr.Calendar.first_day_for_locale(locale)

    if day_number == first_day_number,
      do: date,
      else: calculate_first_day_of_week(Date.add(date, -1), locale)
  end

  defp calculate_next_day_notification(%Date{} = day, timezone) do
    {:ok, send_at} = NaiveDateTime.new(day, ~T[18:00:00])
    {:ok, send_at} = DateTime.from_naive(send_at, timezone)

    if send_at < DateTime.utc_now() do
      calculate_first_day_of_week(Date.add(day, 1), timezone)
    else
      send_at
    end
  end
end