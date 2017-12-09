defmodule EventosWeb.SessionController do
  use EventosWeb, :controller
  alias Eventos.Accounts.User
  alias Eventos.Accounts

  def sign_in(conn, %{"email" => email, "password" => password}) do
    with %User{} = user <- Accounts.find(email) do
      # Attempt to authenticate the user
      with {:ok, token, _claims} <- Accounts.authenticate(%{user: user, password: password}) do
        # Render the token
        render conn, "token.json", token: token
      end
    end
  end

  def sign_out(conn, _params) do
    conn
    |> Eventos.Guardian.Plug.sign_out()
    |> send_resp(204, "")
  end

  def show(conn, _params) do
    user = Eventos.Guardian.Plug.current_resource(conn)

    send_resp(conn, 200, Poison.encode!(%{user: user}))
  end
end