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
  def perform(%{"op" => "before_event_notification", "participant_id" => participant_id}, _job) do
    with %Participant{actor: %Actor{user_id: user_id}, event: %Event{status: :confirmed}} =
           participant <- Events.get_participant(participant_id),
         %User{email: email, locale: locale, settings: %Setting{notification_before_event: true}} <-
           Users.get_user_with_settings!(user_id) do
      email
      |> Notification.before_event_notification(participant, locale)
      |> Mailer.deliver_later()

      :ok
    end
  end

  def perform(%{"op" => "on_day_notification", "user_id" => user_id}, _job) do
    %User{locale: locale, settings: %Setting{timezone: timezone, notification_on_day: true}} =
      user = Users.get_user_with_settings!(user_id)

    now = DateTime.utc_now()
    %DateTime{} = now_shifted = shift_zone(now, timezone)
    start = %{now_shifted | hour: 8, minute: 0, second: 0, microsecond: {0, 0}}
    tomorrow = DateTime.add(start, 3600 * 24)

    with %Page{
           elements: participations,
           total: total
         } <-
           Events.list_participations_for_user(user_id, start, tomorrow, 1, 5),
         true <-
           Enum.all?(participations, fn participation ->
             participation.event.status == :confirmed
           end),
         true <- total > 0 do
      user
      |> Notification.on_day_notification(participations, total, locale)
      |> Mailer.deliver_later()

      :ok
    end
  end

  defp shift_zone(datetime, timezone) do
    case DateTime.shift_zone(datetime, timezone) do
      {:ok, shift_datetime} -> shift_datetime
      {:error, _} -> datetime
    end
  end
end
