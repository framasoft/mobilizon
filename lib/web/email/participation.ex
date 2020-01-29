defmodule Mobilizon.Web.Email.Participation do
  @moduledoc """
  Handles emails sent about participation.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.Participant
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Web.{Email, Gettext}

  @doc """
  Send emails to local user
  """
  def send_emails_to_local_user(
        %Participant{actor: %Actor{user_id: nil, id: actor_id} = _actor} = participation
      ) do
    if actor_id == Config.anonymous_actor_id() do
      %{email: email} = Map.get(participation, :metadata)

      email
      |> participation_updated(participation)
      |> Email.Mailer.deliver_later()
    end

    :ok
  end

  @doc """
  Send emails to local user
  """
  def send_emails_to_local_user(
        %Participant{actor: %Actor{user_id: user_id} = _actor} = participation
      ) do
    with %User{} = user <- Users.get_user!(user_id) do
      user
      |> participation_updated(participation)
      |> Email.Mailer.deliver_later()

      :ok
    end
  end

  @spec participation_updated(String.t() | User.t(), Participant.t(), String.t()) ::
          Bamboo.Email.t()
  def participation_updated(user, participant, locale \\ "en")

  @spec participation_updated(User.t(), Participant.t(), String.t()) :: Bamboo.Email.t()
  def participation_updated(
        %User{email: email},
        %Participant{} = participant,
        locale
      ),
      do: participation_updated(email, participant, locale)

  @spec participation_updated(String.t(), Participant.t(), String.t()) :: Bamboo.Email.t()
  def participation_updated(
        email,
        %Participant{event: event, role: :rejected},
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
    |> assign(:subject, subject)
    |> render(:event_participation_rejected)
  end

  @spec participation_updated(String.t(), Participant.t(), String.t()) :: Bamboo.Email.t()
  def participation_updated(
        email,
        %Participant{event: event, role: :participant},
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
    |> assign(:subject, subject)
    |> render(:anonymous_participation_confirmation)
  end
end
