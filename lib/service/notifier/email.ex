defmodule Mobilizon.Service.Notifier.Email do
  @moduledoc """
  Email notifier
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Config
  alias Mobilizon.Service.Notifier
  alias Mobilizon.Service.Notifier.Email
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Email.Activity, as: EmailActivity
  alias Mobilizon.Web.Email.Mailer

  @behaviour Notifier

  @impl Notifier
  def ready? do
    Config.get(__MODULE__, :enabled)
  end

  @impl Notifier
  def send(%User{} = user, %Activity{} = activity) do
    Email.send(user, [activity])
  end

  @impl Notifier
  def send(%User{email: email, locale: locale}, activities) when is_list(activities) do
    email
    |> EmailActivity.direct_activity(activities, locale)
    |> Mailer.send_email()
  end
end
