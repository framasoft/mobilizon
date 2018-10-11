defmodule MobilizonWeb.SessionController do
  @moduledoc """
  Controller for (event) Sessions
  """
  use MobilizonWeb, :controller

  alias Mobilizon.Events
  alias Mobilizon.Events.Session

  action_fallback(MobilizonWeb.FallbackController)

  def index(conn, _params) do
    sessions = Events.list_sessions()
    render(conn, "index.json", sessions: sessions)
  end

  def create(conn, %{"session" => session_params}) do
    with {:ok, %Session{} = session} <- Events.create_session(session_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", session_path(conn, :show, session))
      |> render("show.json", session: session)
    end
  end

  def show(conn, %{"id" => id}) do
    session = Events.get_session!(id)
    render(conn, "show.json", session: session)
  end

  def show_sessions_for_event(conn, %{"uuid" => event_uuid}) do
    sessions = Events.list_sessions_for_event(event_uuid)
    render(conn, "index.json", sessions: sessions)
  end

  def show_sessions_for_track(conn, %{"id" => track}) do
    sessions = Events.list_sessions_for_track(track)
    render(conn, "index.json", sessions: sessions)
  end

  def update(conn, %{"id" => id, "session" => session_params}) do
    session = Events.get_session!(id)

    with {:ok, %Session{} = session} <- Events.update_session(session, session_params) do
      render(conn, "show.json", session: session)
    end
  end

  def delete(conn, %{"id" => id}) do
    session = Events.get_session!(id)

    with {:ok, %Session{}} <- Events.delete_session(session) do
      send_resp(conn, :no_content, "")
    end
  end
end
