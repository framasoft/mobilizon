defmodule Mobilizon.Web.Email.Notification do
  @moduledoc """
  Handles emails sent about event notifications.
  """
  use Phoenix.Swoosh, view: Mobilizon.Web.EmailView

  import Mobilizon.Web.Gettext

  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Users.{Setting, User}
  alias Mobilizon.Web.Email
  alias Mobilizon.Web.JsonLD.ObjectView

  @spec before_event_notification(String.t(), Participant.t(), String.t()) ::
          Swoosh.Email.t()
  def before_event_notification(
        email,
        %Participant{event: event, role: :participant} = participant,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Don't forget to go to %{title}",
        title: event.title
      )

    [to: email, subject: subject]
    |> Email.base_email()
    |> Email.add_event_attachment(event)
    |> render_body(:before_event_notification, %{
      locale: locale,
      participant: participant,
      subject: subject,
      jsonLDMetadata: build_json_ld(participant)
    })
  end

  @spec on_day_notification(User.t(), list(Participant.t()), pos_integer(), String.t()) ::
          Swoosh.Email.t()
  def on_day_notification(
        %User{email: email, settings: %Setting{timezone: timezone}},
        participations,
        total,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)
    participation = hd(participations)

    subject =
      ngettext("One event planned today", "%{nb_events} events planned today", total,
        nb_events: total
      )

    [to: email, subject: subject]
    |> Email.base_email()
    |> render_body(:on_day_notification, %{
      locale: locale,
      participation: participation,
      participations: participations,
      subject: subject,
      total: total,
      timezone: timezone,
      jsonLDMetadata: build_json_ld(participations)
    })
  end

  @spec weekly_notification(User.t(), list(Participant.t()), pos_integer(), String.t()) ::
          Swoosh.Email.t()
  def weekly_notification(
        %User{email: email, settings: %Setting{timezone: timezone}},
        participations,
        total,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)
    participation = hd(participations)

    subject =
      ngettext("One event planned this week", "%{nb_events} events planned this week", total,
        nb_events: total
      )

    [to: email, subject: subject]
    |> Email.base_email()
    |> render_body(:notification_each_week, %{
      locale: locale,
      participation: participation,
      participations: participations,
      subject: subject,
      total: total,
      timezone: timezone,
      jsonLDMetadata: build_json_ld(participations)
    })
  end

  @spec pending_participation_notification(User.t(), Event.t(), pos_integer()) :: Swoosh.Email.t()
  def pending_participation_notification(
        %User{locale: locale, email: email, settings: %Setting{timezone: timezone}},
        %Event{} = event,
        total
      ) do
    Gettext.put_locale(locale)

    subject =
      ngettext(
        "One participation request for event %{title} to process",
        "%{number_participation_requests} participation requests for event %{title} to process",
        total,
        number_participation_requests: total,
        title: event.title
      )

    [to: email, subject: subject]
    |> Email.base_email()
    |> render_body(:pending_participation_notification, %{
      locale: locale,
      event: event,
      subject: subject,
      total: total,
      timezone: timezone
    })
  end

  @spec build_json_ld(Participant.t()) :: String.t()
  defp build_json_ld(%Participant{} = participant) do
    "participation.json"
    |> ObjectView.render(%{participant: participant})
    |> Jason.encode!()
  end

  defp build_json_ld(participations) when is_list(participations) do
    participations
    |> Enum.map(&ObjectView.render("participation.json", %{participant: &1}))
    |> Jason.encode!()
  end
end
