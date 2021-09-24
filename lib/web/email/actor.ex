defmodule Mobilizon.Web.Email.Actor do
  @moduledoc """
  Handles emails sent about actors status.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Config, Users}
  alias Mobilizon.Events.{Event, Participant}
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
      instance = Config.instance_name()

      subject = gettext("Your participation to %{event} has been cancelled!", event: event.title)

      Email.base_email(to: email, subject: subject)
      |> assign(:locale, locale)
      |> assign(:actor, suspended)
      |> assign(:event, event)
      |> assign(:role, member_role)
      |> assign(:subject, subject)
      |> assign(:instance, instance)
      |> render(:actor_suspension_participants)
      |> Email.Mailer.send_email_later()

      :ok
    end
  end
end
