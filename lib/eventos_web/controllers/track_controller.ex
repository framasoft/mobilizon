defmodule EventosWeb.TrackController do
  @moduledoc """
  Controller for Tracks
  """
  use EventosWeb, :controller

  alias Eventos.Events
  alias Eventos.Events.Track

  action_fallback(EventosWeb.FallbackController)

  def index(conn, _params) do
    tracks = Events.list_tracks()
    render(conn, "index.json", tracks: tracks)
  end

  def create(conn, %{"track" => track_params}) do
    with {:ok, %Track{} = track} <- Events.create_track(track_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", track_path(conn, :show, track))
      |> render("show.json", track: track)
    end
  end

  def show(conn, %{"id" => id}) do
    track = Events.get_track!(id)
    render(conn, "show.json", track: track)
  end

  def update(conn, %{"id" => id, "track" => track_params}) do
    track = Events.get_track!(id)

    with {:ok, %Track{} = track} <- Events.update_track(track, track_params) do
      render(conn, "show.json", track: track)
    end
  end

  def delete(conn, %{"id" => id}) do
    track = Events.get_track!(id)

    with {:ok, %Track{}} <- Events.delete_track(track) do
      send_resp(conn, :no_content, "")
    end
  end
end
