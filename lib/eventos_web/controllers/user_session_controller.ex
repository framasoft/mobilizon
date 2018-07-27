defmodule EventosWeb.UserSessionController do
  @moduledoc """
  Controller for user sessions
  """
  use EventosWeb, :controller
  alias Eventos.Actors.User
  alias Eventos.Actors

  def sign_in(conn, %{"email" => email, "password" => password}) do
    with {:ok, %User{} = user} <- Actors.find_by_email(email),
         {:ok, %User{} = _user} <- User.is_confirmed(user),
         {:ok, token, _claims} <- Actors.authenticate(%{user: user, password: password}) do
      # Render the token
      render(conn, "token.json", %{token: token, user: user})
    else
      {:error, :not_found} ->
        conn
        |> put_status(401)
        |> json(%{"error_msg" => "No such user", "display_error" => "session.error.bad_login"})

      {:error, :unconfirmed} ->
        conn
        |> put_status(401)
        |> json(%{
          "error_msg" => "User is not activated",
          "display_error" => "session.error.not_activated"
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(401)
        |> json(%{"error_msg" => "Bad login", "display_error" => "session.error.bad_login"})
    end
  end

  def sign_out(conn, _params) do
    conn
    |> EventosWeb.Guardian.Plug.sign_out()
    |> send_resp(204, "")
  end
end
