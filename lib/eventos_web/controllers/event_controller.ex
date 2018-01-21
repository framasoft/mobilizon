defmodule EventosWeb.EventController do
  @moduledoc """
  Controller for Events
  """
  use EventosWeb, :controller

  alias Eventos.Events
  alias Eventos.Events.Event
  alias Eventos.Export.ICalendar
  alias Eventos.Addresses

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    events = Events.list_events()
    render(conn, "index.json", events: events)
  end

  def create(conn, %{"event" => event_params}) do
    event_params = %{event_params | "address" => process_address(event_params["address"])}
    with {:ok, %Event{} = event} <- Events.create_event(event_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", event_path(conn, :show, event))
      |> render("show_simple.json", event: event)
    end
  end

  defp process_address(address) do
    case Addresses.process_geom(address["geom"]) do
      {:ok, geom} ->
        %{address | "geom" => geom}
      _ ->
        address
    end
  end

  def show(conn, %{"id" => id}) do
    event = Events.get_event_full!(id)
    render(conn, "show.json", event: event)
  end

  def export_to_ics(conn, %{"id" => id}) do
    event = id
      |> Events.get_event!()
      |> ICalendar.export_event()
    send_resp(conn, 200, event)
  end

  def update(conn, %{"id" => id, "event" => event_params}) do
    event = Events.get_event!(id)

    with {:ok, %Event{} = event} <- Events.update_event(event, event_params) do
      render(conn, "show_simple.json", event: event)
    end
  end

  def delete(conn, %{"id" => id}) do
    event = Events.get_event!(id)
    with {:ok, %Event{}} <- Events.delete_event(event) do
      send_resp(conn, :no_content, "")
    end
  end
end
