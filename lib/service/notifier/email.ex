defmodule Mobilizon.Service.Notifier.Email do
  @moduledoc """
  Email notifier
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.{Config, Users}
  alias Mobilizon.Service.Notifier
  alias Mobilizon.Service.Notifier.{Email, Filter}
  alias Mobilizon.Users.{Setting, User}
  alias Mobilizon.Web.Email.Activity, as: EmailActivity
  alias Mobilizon.Web.Email.Mailer

  import Mobilizon.Service.DateTime,
    only: [
      is_delay_ok_since_last_notification_sent: 1
    ]

  require Logger

  @behaviour Notifier

  @impl Notifier
  def ready? do
    Config.get([__MODULE__, :enabled])
  end

  def send(user, activity, options \\ [])

  @impl Notifier
  def send(%User{} = user, %Activity{} = activity, options) do
    Email.send(user, [activity], options)
  end

  @impl Notifier
  def send(%User{email: email, locale: locale} = user, activities, options)
      when is_list(activities) do
    activities = Enum.filter(activities, &can_send_activity?(&1, user, options))

    if length(activities) > 0 do
      Logger.debug("Found some activities to send by email")

      email
      |> EmailActivity.direct_activity(activities, Keyword.put(options, :locale, locale))
      |> Mailer.send_email()

      save_last_notification_time(user)
      {:ok, :sent}
    else
      Logger.debug("No activities to send by email")
      {:ok, :skipped}
    end
  end

  @doc """
  Send an anonymous activity directly to an email, for anonymous participants for instance
  """
  @spec send_anonymous_activity(String.t(), Activity.t(), Keyword.t()) :: {:ok, :sent}
  def send_anonymous_activity(email, %Activity{} = activity, options) do
    email
    |> EmailActivity.anonymous_activity(activity, options)
    |> Mailer.send_email()

    {:ok, :sent}
  end

  # These notifications are using LegacyNotifierBuilder and don't have any history,
  # so we always send them directly, as long as the setting isn't none
  @always_direct_subjects [
    :participation_event_comment,
    :event_comment_mention,
    :discussion_mention,
    :event_new_comment
  ]

  @spec can_send_activity?(Activity.t(), User.t(), Keyword.t()) :: boolean()
  defp can_send_activity?(
         %Activity{subject: subject} = activity,
         %User{
           settings: %Setting{
             group_notifications: group_notifications,
             last_notification_sent: last_notification_sent
           }
         } = user,
         options
       ) do
    Filter.can_send_activity?(activity, "email", user, &default_activity_behavior/1) &&
      match_group_notifications_setting(
        group_notifications,
        subject,
        last_notification_sent,
        options
      )
  end

  @spec match_group_notifications_setting(
          NotificationPendingNotificationDelay.t(),
          String.t(),
          DateTime.t() | nil,
          Keyword.t()
        ) :: boolean()
  # No notifications at all
  defp match_group_notifications_setting(:none, _, _, _), do: false

  # Every notification
  defp match_group_notifications_setting(:direct, _, _, _), do: true

  # Direct notifications
  defp match_group_notifications_setting(_, subject, _, _)
       when subject in @always_direct_subjects,
       do: true

  # First notification EVER!
  defp match_group_notifications_setting(:one_hour, _, last_notification_sent, _)
       when is_nil(last_notification_sent),
       do: true

  # Delay ok since last notification
  defp match_group_notifications_setting(:one_hour, _, %DateTime{} = last_notification_sent, _) do
    is_delay_ok_since_last_notification_sent(last_notification_sent)
  end

  # This is a recap
  defp match_group_notifications_setting(
         _group_notifications,
         _subject,
         _last_notification_sent,
         options
       ) do
    Keyword.get(options, :recap, false) != false
  end

  @default_behavior %{
    "participation_event_updated" => true,
    "participation_event_comment" => true,
    "event_new_pending_participation" => true,
    "event_new_participation" => false,
    "event_created" => false,
    "event_updated" => false,
    "discussion_updated" => false,
    "post_published" => false,
    "post_updated" => false,
    "resource_updated" => false,
    "member_request" => true,
    "member_updated" => false,
    "user_email_password_updated" => true,
    "event_comment_mention" => true,
    "discussion_mention" => true,
    "event_new_comment" => true
  }

  @spec default_activity_behavior(String.t()) :: boolean()
  defp default_activity_behavior(activity_setting) do
    Map.get(@default_behavior, activity_setting, false)
  end

  @spec save_last_notification_time(User.t()) :: {:ok, Setting.t()} | {:error, Ecto.Changeset.t()}
  defp save_last_notification_time(%User{id: user_id}) do
    attrs = %{user_id: user_id, last_notification_sent: DateTime.utc_now()}

    case Users.get_setting(user_id) do
      nil ->
        Users.create_setting(attrs)

      %Setting{} = setting ->
        Users.update_setting(setting, attrs)
    end
  end
end
