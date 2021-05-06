defmodule Mobilizon.Service.Notifier.Push do
  @moduledoc """
  WebPush notifier
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.{Config, Users}
  alias Mobilizon.Service.Notifier
  alias Mobilizon.Service.Notifier.Push
  alias Mobilizon.Storage.Page
  alias Mobilizon.Users.User

  @behaviour Notifier

  @impl Notifier
  def ready? do
    Config.get(__MODULE__, :enabled)
  end

  @impl Notifier
  def send(%User{id: user_id} = _user, %Activity{} = activity, _opts) do
    %Page{elements: subscriptions} = Users.list_user_push_subscriptions(user_id, 1, 100)
    Enum.each(subscriptions, &send_subscription(activity, &1))
  end

  @impl Notifier
  def send(%User{} = user, activities, opts) when is_list(activities) do
    Enum.each(activities, &Push.send(user, &1, opts))
  end

  defp payload(%Activity{subject: subject}) do
    %{
      title: subject
    }
    |> Jason.encode!()
  end

  defp send_subscription(activity, subscription) do
    activity
    |> payload()
    |> WebPushEncryption.send_web_push(subscription)
  end
end
