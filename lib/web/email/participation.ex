defmodule Mobilizon.Web.Email.Participation do
  @moduledoc """
  Handles emails sent about participation.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Config, Events, Users}
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email
  alias Mobilizon.Web.JsonLD.ObjectView

  @doc """
  Send participation emails to local user

  If the actor is anonymous, use information in metadata
  """
  def send_emails_to_local_user(
        %Participant{actor: %Actor{user_id: nil, id: actor_id} = _actor} = participation
      ) do
    if actor_id == Config.anonymous_actor_id() do
      %{email: email, locale: locale} = Map.get(participation, :metadata)
      locale = locale || "en"

      email
      |> participation_updated(participation, locale)
      |> Email.Mailer.send_email_later()
    end

    :ok
  end

  def send_emails_to_local_user(
        %Participant{actor: %Actor{user_id: user_id} = _actor} = participation
      ) do
    with %User{locale: locale} = user <- Users.get_user!(user_id) do
      user
      |> participation_updated(participation, locale)
      |> Email.Mailer.send_email_later()

      :ok
    end
  end

  @spec participation_updated(String.t() | User.t(), Participant.t(), String.t()) ::
          Bamboo.Email.t()
  def participation_updated(user, participant, locale \\ "en")

  def participation_updated(
        %User{email: email},
        %Participant{} = participant,
        locale
      ),
      do: participation_updated(email, participant, locale)

  def participation_updated(
        email,
        %Participant{event: event, role: :rejected} = participant,
        locale
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Your participation to event %{title} has been rejected",
        title: event.title
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:event, event)
    |> assign(:jsonLDMetadata, json_ld(participant))
    |> assign(:subject, subject)
    |> render(:event_participation_rejected)
  end

  def participation_updated(
        email,
        %Participant{event: %Event{join_options: :free} = event, role: :participant} =
          participant,
        locale
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Your participation to event %{title} has been confirmed",
        title: event.title
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:event, event)
    |> assign(:subject, subject)
    |> assign(:jsonLDMetadata, json_ld(participant))
    |> render(:event_participation_confirmed)
  end

  def participation_updated(
        email,
        %Participant{event: event, role: :participant} = participant,
        locale
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Your participation to event %{title} has been approved",
        title: event.title
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:event, event)
    |> assign(:subject, subject)
    |> assign(:jsonLDMetadata, json_ld(participant))
    |> Email.add_event_attachment(event)
    |> render(:event_participation_approved)
  end

  @spec anonymous_participation_confirmation(String.t(), Participant.t(), String.t()) ::
          Bamboo.Email.t()
  def anonymous_participation_confirmation(
        email,
        %Participant{event: event, role: :not_confirmed} = participant,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Confirm your participation to event %{title}",
        title: event.title
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:participant, participant)
    |> assign(:jsonLDMetadata, json_ld(participant))
    |> assign(:subject, subject)
    |> render(:anonymous_participation_confirmation)
  end

  defp json_ld(participant) do
    event = Events.get_event_with_preload!(participant.event_id)

    "participation.json"
    |> ObjectView.render(%{participant: %Participant{participant | event: event}})
    |> Jason.encode!()
  end
end
