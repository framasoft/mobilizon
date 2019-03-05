defmodule Mobilizon.Users.Service.ResetPassword do
  @moduledoc false

  require Logger

  alias Mobilizon.Users.User
  alias Mobilizon.{Mailer, Repo, Users}
  alias Mobilizon.Email.User, as: UserEmail
  alias Mobilizon.Users.Service.Tools

  @doc """
  Check that the provided token is correct and update provided password
  """
  @spec check_reset_password_token(String.t(), String.t()) :: tuple
  def check_reset_password_token(password, token) do
    with %User{} = user <- Users.get_user_by_reset_password_token(token),
         {:ok, %User{} = user} <-
           Repo.update(
             User.password_reset_changeset(user, %{
               "password" => password,
               "reset_password_sent_at" => nil,
               "reset_password_token" => nil
             })
           ) do
      {:ok, user}
    else
      {:error, %Ecto.Changeset{errors: [password: {"registration.error.password_too_short", _}]}} ->
        {:error,
         "The password you have choosen is too short. Please make sure your password contains at least 6 charaters."}

      _err ->
        {:error,
         "The token you provided is invalid. Make sure that the URL is exactly the one provided inside the email you got."}
    end
  end

  @doc """
  Send the email reset password, if it's not too soon since the last send
  """
  @spec send_password_reset_email(User.t(), String.t()) :: tuple
  def send_password_reset_email(%User{} = user, locale \\ "en") do
    with :ok <- Tools.we_can_send_email(user, :reset_password_sent_at),
         {:ok, %User{} = user_updated} <-
           Repo.update(
             User.send_password_reset_changeset(user, %{
               "reset_password_token" => Tools.random_string(30),
               "reset_password_sent_at" => DateTime.utc_now() |> DateTime.truncate(:second)
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
end
