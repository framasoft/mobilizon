defmodule MobilizonWeb.Email.Participation do
  @moduledoc """
  Handles emails sent about participation.
  """

  use Bamboo.Phoenix, view: MobilizonWeb.EmailView

  import Bamboo.Phoenix

  import MobilizonWeb.Gettext

  alias Mobilizon.Users.User
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Participant

  alias MobilizonWeb.Email

  @doc """
  Send emails to local user
  """
  def send_emails_to_local_user(
        %Participant{actor: %Actor{user_id: nil} = _actor} = _participation
      ),
      do: :ok

  @doc """
  Send emails to local user
  """
  def send_emails_to_local_user(
        %Participant{actor: %Actor{user_id: user_id} = _actor} = participation
      ) do
    with %User{} = user <- Mobilizon.Users.get_user!(user_id) do
      user
      |> participation_updated(participation)
      |> Email.Mailer.deliver_later()

      :ok
    end
  end

  @spec participation_updated(User.t(), Participant.t(), String.t()) :: Bamboo.Email.t()
  def participation_updated(user, participant, locale \\ "en")

  def participation_updated(
        %User{email: email},
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

  @spec participation_updated(User.t(), Participant.t(), String.t()) :: Bamboo.Email.t()
  def participation_updated(
        %User{email: email},
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
end
