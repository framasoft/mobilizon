defmodule EventosWeb.UserController do
  @moduledoc """
  Controller for Users
  """
  use EventosWeb, :controller

  alias Eventos.Actors
  alias Eventos.Actors.User
  alias Eventos.Repo

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    users = Actors.list_users_with_actors()
    render(conn, "index.json", users: users)
  end

  def register(conn, %{"username" => username, "email" => email, "password" => password}) do
    case Actors.register(%{email: email, password: password, username: username}) do
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

  def show_current_actor(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    user
    |> Repo.preload(:actor)
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
    user = Actors.get_user!(id)

    with {:ok, %User{} = user} <- Actors.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Actors.get_user!(id)
    with {:ok, %User{}} <- Actors.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
