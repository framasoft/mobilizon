defmodule Mobilizon.Service.Notifier.Push do
  @moduledoc """
  WebPush notifier
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.{Config, Users}
  alias Mobilizon.Service.Activity.{Renderer, Utils}
  alias Mobilizon.Service.Notifier
  alias Mobilizon.Service.Notifier.{Filter, Push}
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.{PushSubscription, User}

  @behaviour Notifier

  @impl Notifier
  def ready? do
    Config.get(__MODULE__, :enabled)
  end

  @impl Notifier
  def send(user, activity, options \\ [])

  def send(%User{id: user_id, locale: locale} = user, %Activity{} = activity, options) do
    if can_send_activity?(activity, user) do
      options = Keyword.put_new(options, :locale, locale)

      %Page{elements: subscriptions} = Users.list_user_push_subscriptions(user_id, 1, 100)
      Enum.each(subscriptions, &send_subscription(activity, convert_subscription(&1), options))
      {:ok, :sent}
    else
      {:ok, :skipped}
    end
  end

  @impl Notifier
  def send(%User{} = user, activities, options) when is_list(activities) do
    Enum.map(activities, &Push.send(user, &1, options))
  end

  @spec can_send_activity?(Activity.t(), User.t()) :: boolean()
  defp can_send_activity?(%Activity{} = activity, %User{} = user) do
    Filter.can_send_activity?(activity, "push", user, &default_activity_behavior/1)
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
    "user_email_password_updated" => false,
    "event_comment_mention" => true,
    "discussion_mention" => false,
    "event_new_comment" => false
  }

  @spec default_activity_behavior(String.t()) :: boolean()
  defp default_activity_behavior(activity_setting) do
    Map.get(@default_behavior, activity_setting, false)
  end

  defp send_subscription(activity, subscription, options) do
    activity
    |> payload(options)
    |> WebPushEncryption.send_web_push(subscription)
  end

  defp payload(%Activity{} = activity, options) do
    activity
    |> Utils.add_activity_object()
    |> Renderer.render(options)
    |> Jason.encode!()
  end

  defp convert_subscription(%PushSubscription{} = subscription) do
    %{
      endpoint: subscription.endpoint,
      keys: %{auth: subscription.auth, p256dh: subscription.p256dh}
    }
  end
end
