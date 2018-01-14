defmodule EventosWeb.UserController do
  @moduledoc """
  Controller for Users
  """
  use EventosWeb, :controller

  alias Eventos.Accounts
  alias Eventos.Accounts.User
  alias Eventos.Repo

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users_with_accounts()
    render(conn, "index.json", users: users)
  end

  def register(conn, %{"username" => username, "email" => email, "password" => password}) do
    case Accounts.register(%{email: email, password: password, username: username}) do
      {:ok, %User{} = user} ->
        {:ok, token, _claims} = EventosWeb.Guardian.encode_and_sign(user)
        conn
        |> put_status(:created)
        |> render("show_with_token.json", %{token: token, user: user})
      {:error, error} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{"msg" => handle_changeset_errors(error)}))
    end
  end

  def show_current_account(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    user
    |> Repo.preload(:account)
    render(conn, "show_simple.json", user: user)
  end

  defp handle_changeset_errors(errors) do
    errors
    |> Enum.map(fn {field, detail} ->
      "#{field} " <> render_detail(detail)
    end)
    |> Enum.join
  end


  defp render_detail({message, values}) do
    Enum.reduce values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end
  end

  defp render_detail(message) do
    message
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
