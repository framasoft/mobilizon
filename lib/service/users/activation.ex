defmodule Mobilizon.Service.Users.Activation do
  @moduledoc false

  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Service.Users.Tools

  alias MobilizonWeb.Email

  require Logger

  @doc false
  def check_confirmation_token(token) when is_binary(token) do
    with %User{} = user <- Users.get_user_by_activation_token(token),
         {:ok, %User{} = user} <-
           Users.update_user(user, %{
             "confirmed_at" => DateTime.utc_now() |> DateTime.truncate(:second),
             "confirmation_sent_at" => nil,
             "confirmation_token" => nil
           }) do
      Logger.info("User #{user.email} has been confirmed")
      {:ok, user}
    else
      _err ->
        {:error, :invalid_token}
    end
  end

  def resend_confirmation_email(%User{} = user, locale \\ "en") do
    with :ok <- Tools.we_can_send_email(user, :confirmation_sent_at),
         {:ok, user} <-
           Users.update_user(user, %{
             "confirmation_sent_at" => DateTime.utc_now() |> DateTime.truncate(:second)
           }) do
      send_confirmation_email(user, locale)
      Logger.info("Sent confirmation email again to #{user.email}")
      {:ok, user.email}
    end
  end

  def send_confirmation_email(%User{} = user, locale \\ "en") do
    user
    |> Email.User.confirmation_email(locale)
    |> Email.Mailer.deliver_later()
  end
end
