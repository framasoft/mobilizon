defmodule Mobilizon.Web.Email.Group do
  @moduledoc """
  Handles emails sent about group changes.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.{Actors, Config, Users}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Events.Event
  alias Mobilizon.Users.{Setting, User}
  alias Mobilizon.Web.Email

  @spec notify_of_new_event(Event.t()) :: :ok
  def notify_of_new_event(%Event{attributed_to: %Actor{} = group} = event) do
    # TODO: When we have events restricted to members, don't send emails to followers
    group
    |> Actors.list_actors_to_notify_from_group_event()
    |> Enum.each(&notify_follower(event, group, &1))
  end

  def notify_of_new_event(%Event{}), do: :ok

  defp notify_follower(%Event{} = _event, %Actor{}, %Actor{user_id: nil}), do: :ok

  defp notify_follower(%Event{} = event, %Actor{type: :Group} = group, %Actor{
         id: profile_id,
         user_id: user_id
       }) do
    %User{
      email: email,
      locale: locale,
      settings: %Setting{timezone: timezone},
      activity_settings: activity_settings
    } = Users.get_user_with_activity_settings!(user_id)

    if profile_id != event.organizer_actor_id &&
         accepts_new_events_notifications(activity_settings) do
      Gettext.put_locale(locale)

      subject =
        gettext(
          "📅 Just scheduled by %{group}: %{event}",
          group: Actor.display_name(group),
          event: event.title
        )

      Email.base_email(to: email, subject: subject)
      |> assign(:locale, locale)
      |> assign(:group, group)
      |> assign(:event, event)
      |> assign(:timezone, timezone)
      |> assign(:subject, subject)
      |> render(:event_group_follower_notification)
      |> Email.Mailer.send_email_later()

      :ok
    end
  end

  @spec accepts_new_events_notifications(list()) :: boolean()
  defp accepts_new_events_notifications(activity_settings) do
    case Enum.find(activity_settings, &(&1.key == "event_created" && &1.method == "email")) do
      nil -> false
      %{enabled: enabled} -> enabled
    end
  end

  # TODO : def send_confirmation_to_inviter()

  @member_roles [:administrator, :moderator, :member]
  @spec send_group_suspension_notification(Member.t()) :: :ok
  def send_group_suspension_notification(%Member{actor: %Actor{user_id: nil}}), do: :ok

  def send_group_suspension_notification(%Member{role: role}) when role not in @member_roles,
    do: :ok

  def send_group_suspension_notification(%Member{
        actor: %Actor{user_id: user_id},
        parent: %Actor{domain: nil} = group,
        role: member_role
      }) do
    with %User{email: email, locale: locale} <- Users.get_user!(user_id) do
      Gettext.put_locale(locale)

      subject =
        gettext(
          "The group %{group} has been suspended on %{instance}",
          group: group.name,
          instance: Config.instance_name()
        )

      Email.base_email(to: email, subject: subject)
      |> assign(:locale, locale)
      |> assign(:group, group)
      |> assign(:role, member_role)
      |> assign(:subject, subject)
      |> render(:group_suspension)
      |> Email.Mailer.send_email_later()

      :ok
    end
  end
end
