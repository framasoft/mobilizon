defmodule Mobilizon.Service.Notifier.Push do
  @moduledoc """
  WebPush notifier
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.{Config, Users}
  alias Mobilizon.Service.Activity.{Renderer, Utils}
  alias Mobilizon.Service.Notifier
  alias Mobilizon.Service.Notifier.Push
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.{PushSubscription, User}

  @behaviour Notifier

  @impl Notifier
  def ready? do
    Config.get(__MODULE__, :enabled)
  end

  @impl Notifier
  def send(user, activity, options \\ [])

  def send(%User{id: user_id, locale: locale} = _user, %Activity{} = activity, options) do
    options = Keyword.put_new(options, :locale, locale)

    %Page{elements: subscriptions} = Users.list_user_push_subscriptions(user_id, 1, 100)
    Enum.map(subscriptions, &send_subscription(activity, convert_subscription(&1), options))
  end

  @impl Notifier
  def send(%User{} = user, activities, options) when is_list(activities) do
    Enum.map(activities, &Push.send(user, &1, options))
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
