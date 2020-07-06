defmodule Mobilizon.Web.AuthController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  require Logger
  plug(:put_layout, false)

  plug(Ueberauth)

  def request(conn, %{"provider" => provider} = _params) do
    redirect(conn, to: "/login?code=Login Provider not found&provider=#{provider}")
  end

  def callback(
        %{assigns: %{ueberauth_failure: fails}} = conn,
        %{"provider" => provider} = _params
      ) do
    Logger.warn("Unable to login user with #{provider} #{inspect(fails)}")

    redirect(conn, to: "/login?code=Error with Login Provider&provider=#{provider}")
  end

  def callback(
        %{assigns: %{ueberauth_auth: %Ueberauth.Auth{strategy: strategy} = auth}} = conn,
        _params
      ) do
    email = email_from_ueberauth(auth)
    [_, _, _, strategy] = strategy |> to_string() |> String.split(".")
    strategy = String.downcase(strategy)

    user =
      with {:valid_email, false} <- {:valid_email, is_nil(email) or email == ""},
           {:error, :user_not_found} <- Users.get_user_by_email(email),
           {:ok, %User{} = user} <- Users.create_external(email, strategy) do
        user
      else
        {:ok, %User{} = user} ->
          user

        {:error, error} ->
          {:error, error}

        error ->
          {:error, error}
      end

    with %User{} = user <- user,
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           Authenticator.generate_tokens(user) do
      Logger.info("Logged-in user \"#{email}\" through #{strategy}")

      render(conn, "callback.html", %{
        access_token: access_token,
        refresh_token: refresh_token,
        user: user
      })
    else
      err ->
        Logger.warn("Unable to login user \"#{email}\" #{inspect(err)}")
        redirect(conn, to: "/login?code=Error with Login Provider&provider=#{strategy}")
    end
  end

  # Github only give public emails as part of the user profile,
  # so we explicitely request all user emails and filter on the primary one
  defp email_from_ueberauth(%Ueberauth.Auth{
         strategy: Ueberauth.Strategy.Github,
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"emails" => emails}}}
       })
       when length(emails) > 0,
       do: emails |> Enum.find(& &1["primary"]) |> (& &1["email"]).()

  defp email_from_ueberauth(%Ueberauth.Auth{
         extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{"email" => email}}}
       })
       when not is_nil(email) and email != "",
       do: email

  defp email_from_ueberauth(_), do: nil
end
