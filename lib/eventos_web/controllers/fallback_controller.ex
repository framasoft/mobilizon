defmodule EventosWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use EventosWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(EventosWeb.ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {:error, nil}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(EventosWeb.ErrorView, "invalid_request.json")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(EventosWeb.ErrorView, :"404")
  end
end
