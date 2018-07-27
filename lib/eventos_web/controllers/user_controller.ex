defmodule EventosWeb.UserController do
  @moduledoc """
  Controller for Users
  """
  use EventosWeb, :controller

  alias Eventos.Actors
  alias Eventos.Actors.User
  alias Eventos.Repo
  alias Eventos.Actors.Service.{Activation, ResetPassword}

  action_fallback(EventosWeb.FallbackController)

  def index(conn, _params) do
    users = Actors.list_users_with_actors()
    render(conn, "index.json", users: users)
  end

  def register(conn, %{"username" => username, "email" => email, "password" => password}) do
    with {:ok, %User{} = user} <-
           Actors.register(%{email: email, password: password, username: username}) do
      Activation.send_confirmation_email(user, "locale")

      conn
      |> put_status(:created)
      |> render("confirmation.json", %{user: user})
    end
  end

  def validate(conn, %{"token" => token}) do
    with {:ok, %User{} = user} <- Activation.check_confirmation_token(token) do
      {:ok, token, _claims} = EventosWeb.Guardian.encode_and_sign(user)

      conn
      |> put_resp_header("location", user_path(conn, :show_current_actor))
      |> render("show_with_token.json", %{user: user, token: token})
    else
      {:error, msg} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => msg})
    end
  end

  def resend_confirmation(conn, %{"email" => email}) do
    with {:ok, %User{} = user} <- Actors.find_by_email(email),
         false <- is_nil(user.confirmation_token),
         true <-
           Timex.before?(Timex.shift(user.confirmation_sent_at, hours: 1), DateTime.utc_now()) do
      Activation.resend_confirmation_email(user)
      render(conn, "confirmation.json", %{user: user})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => "Unable to find an user with this email"})

      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => "Unable to resend the validation token"})
    end
  end

  def send_reset_password(conn, %{"email" => email}) do
    with {:ok, %User{} = user} <- Actors.find_by_email(email),
         {:ok, _} <- ResetPassword.send_password_reset_email(user) do
      render(conn, "password_reset.json", %{user: user})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => "Unable to find an user with this email"})

      {:error, :email_too_soon} ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => "You requested a new reset password too early"})
    end
  end

  def reset_password(conn, %{"password" => password, "token" => token}) do
    with {:ok, %User{} = user} <- ResetPassword.check_reset_password_token(password, token) do
      {:ok, token, _claims} = EventosWeb.Guardian.encode_and_sign(user)
      render(conn, "show_with_token.json", %{user: user, token: token})
    else
      {:error, :invalid_token} ->
        conn
        |> put_status(:not_found)
        |> json(%{"errors" => %{"token" => ["Wrong token for password reset"]}})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(EventosWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show_current_actor(conn, _params) do
    user =
      conn
      |> Guardian.Plug.current_resource()
      |> Repo.preload(:actors)

    render(conn, "show_simple.json", user: user)
  end

  defp handle_changeset_errors(errors) do
    errors
    |> Enum.map(fn {field, detail} ->
      "#{field} " <> render_detail(detail)
    end)
    |> Enum.join()
  end

  defp render_detail({message, values}) do
    Enum.reduce(values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
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
