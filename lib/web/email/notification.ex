defmodule Mobilizon.Web.Email.Notification do
  @moduledoc """
  Handles emails sent about event notifications.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Users.{Setting, User}
  alias Mobilizon.Web.{Email, Gettext}

  @spec before_event_notification(String.t(), Participant.t(), String.t()) ::
          Bamboo.Email.t()
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

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:participant, participant)
    |> assign(:subject, subject)
    |> Email.add_event_attachment(event)
    |> render(:before_event_notification)
  end

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

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:participation, participation)
    |> assign(:participations, participations)
    |> assign(:total, total)
    |> assign(:timezone, timezone)
    |> assign(:subject, subject)
    |> render(:on_day_notification)
  end

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

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:participation, participation)
    |> assign(:participations, participations)
    |> assign(:total, total)
    |> assign(:timezone, timezone)
    |> assign(:subject, subject)
    |> render(:notification_each_week)
  end

  def pending_participation_notification(
        %User{locale: locale, email: email},
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

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:event, event)
    |> assign(:total, total)
    |> assign(:subject, subject)
    |> render(:pending_participation_notification)
  end
end
