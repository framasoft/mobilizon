defmodule Mobilizon.Service.Workers.Notification do
  @moduledoc """
  Worker to send notifications
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users
  alias Mobilizon.Users.{Setting, User}
  alias Mobilizon.Web.Email.{Mailer, Notification}

  use Mobilizon.Service.Workers.Helper, queue: "mailers"

  @impl Oban.Worker
  def perform(%Job{
        args: %{"op" => "before_event_notification", "participant_id" => participant_id}
      }) do
    with %Participant{actor: %Actor{user_id: user_id}, event: %Event{status: :confirmed}} =
           participant <- Events.get_participant(participant_id),
         %User{email: email, locale: locale, settings: %Setting{notification_before_event: true}} <-
           Users.get_user_with_settings!(user_id) do
      email
      |> Notification.before_event_notification(participant, locale)
      |> Mailer.send_email_later()

      :ok
    end
  end

  def perform(%Job{
        args: %{"op" => "on_day_notification", "user_id" => user_id}
      }) do
    with %User{locale: locale, settings: %Setting{timezone: timezone, notification_on_day: true}} =
           user <- Users.get_user_with_settings!(user_id),
         {start, tomorrow} <- calculate_start_end(1, timezone),
         %Page{
           elements: participations,
           total: total
         }
         when total > 0 <-
           Events.list_participations_for_user(user_id, start, tomorrow, 1, 5),
         participations <-
           Enum.filter(participations, fn participation ->
             participation.event.status == :confirmed
           end),
         true <- length(participations) > 0 do
      user
      |> Notification.on_day_notification(participations, total, locale)
      |> Mailer.send_email_later()

      :ok
    else
      _ -> :ok
    end
  end

  def perform(%Job{
        args: %{"op" => "weekly_notification", "user_id" => user_id}
      }) do
    with %User{
           locale: locale,
           settings: %Setting{timezone: timezone, notification_each_week: true}
         } = user <- Users.get_user_with_settings!(user_id),
         {start, end_week} <- calculate_start_end(7, timezone),
         %Page{
           elements: participations,
           total: total
         }
         when total > 0 <-
           Events.list_participations_for_user(user_id, start, end_week, 1, 5),
         participations <-
           Enum.filter(participations, fn participation ->
             participation.event.status == :confirmed
           end),
         true <- length(participations) > 0 do
      user
      |> Notification.weekly_notification(participations, total, locale)
      |> Mailer.send_email_later()

      :ok
    else
      _err ->
        :ok
    end
  end

  def perform(%Job{
        args: %{
          "op" => "pending_participation_notification",
          "user_id" => user_id,
          "event_id" => event_id
        }
      }) do
    with %User{} = user <- Users.get_user(user_id),
         {:ok, %Event{} = event} <- Events.get_event(event_id),
         %Page{total: total} when total > 0 <-
           Events.list_participants_for_event(event_id, [:not_approved]) do
      user
      |> Notification.pending_participation_notification(event, total)
      |> Mailer.send_email_later()

      :ok
    else
      err ->
        require Logger
        Logger.debug(inspect(err))
    end
  end

  defp shift_zone(datetime, timezone) do
    case DateTime.shift_zone(datetime, timezone) do
      {:ok, shift_datetime} -> shift_datetime
      {:error, _} -> datetime
    end
  end

  defp calculate_start_end(days, timezone) do
    now = DateTime.utc_now()
    %DateTime{} = now_shifted = shift_zone(now, timezone)
    start = %{now_shifted | hour: 8, minute: 0, second: 0, microsecond: {0, 0}}

    {:ok, %NaiveDateTime{} = tomorrow} =
      Date.utc_today() |> Date.add(days) |> NaiveDateTime.new(~T[08:00:00])

    {:ok, %DateTime{} = tomorrow} = DateTime.from_naive(tomorrow, timezone)
    {start, tomorrow}
  end
end
