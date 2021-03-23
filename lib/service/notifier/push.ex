defmodule Mobilizon.Service.Notifier.Push do
  @moduledoc """
  WebPush notifier
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Config
  alias Mobilizon.Service.Notifier
  alias Mobilizon.Service.Notifier.Push
  alias Mobilizon.Users.User

  @behaviour Notifier

  @impl Notifier
  def ready? do
    Config.get(__MODULE__, :enabled)
  end

  @impl Notifier
  def send(%User{} = _user, %Activity{} = activity) do
    # Get user's subscriptions
    activity
    |> payload()

    # |> WebPushEncryption.send_web_push()
  end

  @impl Notifier
  def send(%User{} = user, activities) when is_list(activities) do
    Enum.each(activities, &Push.send(user, &1))
  end

  defp payload(%Activity{subject: subject}) do
    %{
      title: subject
    }
    |> Jason.encode!()
  end
end
