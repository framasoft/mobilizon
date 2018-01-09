defmodule EventosWeb.SessionController do
  use EventosWeb, :controller
  alias Eventos.Accounts.User
  alias Eventos.Accounts

  def sign_in(conn, %{"email" => email, "password" => password}) do
    with %User{} = user <- Accounts.find(email) do
      # Attempt to authenticate the user
      with {:ok, token, _claims} <- Accounts.authenticate(%{user: user, password: password}) do
        # Render the token
        user = Eventos.Repo.preload user, :account
        render conn, "token.json", %{token: token, user: user}
      end
      send_resp(conn, 400, "Bad login")
    end
    send_resp(conn, 400, "No such user")
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