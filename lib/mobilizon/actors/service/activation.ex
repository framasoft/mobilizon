defmodule Mobilizon.Actors.Service.Activation do
  @moduledoc false

  alias Mobilizon.{Mailer, Repo, Actors.User, Actors}
  alias Mobilizon.Email.User, as: UserEmail

  require Logger

  @doc false
  def check_confirmation_token(token) when is_binary(token) do
    with %User{} = user <- Repo.get_by(User, confirmation_token: token),
         {:ok, %User{} = user} <-
           Actors.update_user(user, %{
             "confirmed_at" => DateTime.utc_now(),
             "confirmation_sent_at" => nil,
             "confirmation_token" => nil
           }) do
      {:ok, Repo.preload(user, :actors)}
    else
      _err ->
        {:error, "Invalid token"}
    end
  end

  def resend_confirmation_email(%User{} = user, locale \\ "en") do
    {:ok, user} = Actors.update_user(user, %{"confirmation_sent_at" => DateTime.utc_now()})
    send_confirmation_email(user, locale)
  end

  def send_confirmation_email(%User{} = user, locale \\ "en") do
    user
    |> UserEmail.confirmation_email(locale)
    |> Mailer.deliver_later()
  end
end
