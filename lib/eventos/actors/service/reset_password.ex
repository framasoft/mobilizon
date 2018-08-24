defmodule Eventos.Actors.Service.ResetPassword do
  @moduledoc false

  require Logger

  alias Eventos.{Mailer, Repo, Actors.User}
  alias Eventos.Email.User, as: UserEmail

  @doc """
  Check that the provided token is correct and update provided password
  """
  @spec check_reset_password_token(String.t(), String.t()) :: tuple
  def check_reset_password_token(password, token) do
    with %User{} = user <- Repo.get_by(User, reset_password_token: token),
         {:ok, %User{} = user} <-
           Repo.update(
             User.password_reset_changeset(user, %{
               "password" => password,
               "reset_password_sent_at" => nil,
               "reset_password_token" => nil
             })
           ) do
      {:ok, Repo.preload(user, :actors)}
    else
      err ->
        {:error, :invalid_token}
    end
  end

  @doc """
  Send the email reset password, if it's not too soon since the last send
  """
  @spec send_password_reset_email(User.t(), String.t()) :: tuple
  def send_password_reset_email(%User{} = user, locale \\ "en") do
    with :ok <- we_can_send_email(user),
         {:ok, %User{} = user_updated} <-
           Repo.update(
             User.send_password_reset_changeset(user, %{
               "reset_password_token" => random_string(30),
               "reset_password_sent_at" => DateTime.utc_now()
             })
           ) do
      mail =
        user_updated
        |> UserEmail.reset_password_email(locale)
        |> Mailer.deliver_later()

      {:ok, mail}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec random_string(integer) :: String.t()
  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
  end

  @spec we_can_send_email(User.t()) :: boolean
  defp we_can_send_email(%User{} = user) do
    case user.reset_password_sent_at do
      nil ->
        :ok

      _ ->
        case Timex.before?(Timex.shift(user.reset_password_sent_at, hours: 1), DateTime.utc_now()) do
          true ->
            :ok

          false ->
            {:error, :email_too_soon}
        end
    end
  end
end
