defmodule EventosWeb.UserSessionController do
  @moduledoc """
  Controller for user sessions
  """
  use EventosWeb, :controller
  alias Eventos.Accounts.User
  alias Eventos.Accounts

  def sign_in(conn, %{"email" => email, "password" => password}) do
    case Accounts.find_by_email(email) do
      %User{} = user ->
        # Attempt to authenticate the user
        case Accounts.authenticate(%{user: user, password: password}) do
          {:ok, token, _claims} ->
            # Render the token
            render conn, "token.json", %{token: token, user: user}
          _ ->
            send_resp(conn, 400, Poison.encode!(%{"error_msg" => "Bad login", "display_error" => "session.error.bad_login", "error_code" => 400}))
        end
      _ ->
        send_resp(conn, 400, Poison.encode!(%{"error_msg" => "No such user", "display_error" => "session.error.bad_login", "error_code" => 400}))
    end
  end

  def sign_out(conn, _params) do
    conn
    |> EventosWeb.Guardian.Plug.sign_out()
    |> send_resp(204, "")
  end
end
