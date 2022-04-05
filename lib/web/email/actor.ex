defmodule Mobilizon.Web.Email.Actor do
  @moduledoc """
  Handles emails sent about actors status.
  """
  use Phoenix.Swoosh, view: Mobilizon.Web.EmailView

  import Mobilizon.Web.Gettext

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email

  @doc """
  Send a notification to participants from events organized by an actor that is going to be suspended
  """
  @spec send_notification_event_participants_from_suspension(Participant.t(), Actor.t()) ::
          :ok
  def send_notification_event_participants_from_suspension(
        %Participant{
          actor: %Actor{user_id: nil}
        },
        _suspended
      ),
      do: :ok

  def send_notification_event_participants_from_suspension(%Participant{role: role}, _suspended)
      when role not in [:participant, :moderator, :administrator],
      do: :ok

  def send_notification_event_participants_from_suspension(
        %Participant{
          actor: %Actor{user_id: user_id},
          event: %Event{} = event,
          role: member_role
        },
        %Actor{} = suspended
      ) do
    with %User{email: email, locale: locale} <- Users.get_user!(user_id) do
      Gettext.put_locale(locale)

      subject = gettext("Your participation to %{event} has been cancelled!", event: event.title)

      [to: email, subject: subject]
      |> Email.base_email()
      |> render_body(:actor_suspension_participants, %{
        locale: locale,
        actor: suspended,
        event: event,
        role: member_role,
        subject: subject
      })
      |> Email.Mailer.send_email()

      :ok
    end
  end
end
