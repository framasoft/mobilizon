defmodule MobilizonWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use MobilizonWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(MobilizonWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, nil}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(MobilizonWeb.ErrorView)
    |> render("invalid_request.json")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(MobilizonWeb.ErrorView)
    |> render(:"404")
  end
end
