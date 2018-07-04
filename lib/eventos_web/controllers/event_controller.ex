defmodule EventosWeb.EventController do
  @moduledoc """
  Controller for Events
  """
  use EventosWeb, :controller

  alias Eventos.Events
  alias Eventos.Events.Event
  alias Eventos.Export.ICalendar
  alias Eventos.Addresses

  import Logger

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    events = Events.list_events()
    render(conn, "index.json", events: events)
  end

  def create(conn, %{"event" => event_params}) do
    event_params = process_event_address(event_params)
    Logger.debug("creating event with")
    Logger.debug(inspect event_params)
    with {:ok, %Event{} = event} <- Events.create_event(event_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", event_path(conn, :show, event.uuid))
      |> render("show_simple.json", event: event)
    end
  end

  defp process_event_address(event) do
    if Map.has_key?(event, "address_type") && event["address_type"] === :physical do
      address = event["physical_address"]
      geom = EventosWeb.AddressController.process_geom(address["geom"])
      address = case geom do
        nil ->
          address
        _ ->
          %{address | "geom" => geom}
      end
      %{event | "physical_address" => address}
    else
      event
    end
  end

  def search(conn, %{"name" => name}) do
    events = Events.find_events_by_name(name)
    render(conn, "index.json", events: events)
  end

  def show(conn, %{"uuid" => uuid}) do
    case Events.get_event_full_by_uuid(uuid) do
      nil ->
        send_resp(conn, 404, "")
      event ->
        render(conn, "show.json", event: event)
    end
  end

  def export_to_ics(conn, %{"uuid" => uuid}) do
    event = uuid |> Events.get_event_full_by_uuid() |> ICalendar.export_event()
    send_resp(conn, 200, event)
  end

  def update(conn, %{"uuid" => uuid, "event" => event_params}) do
    event = Events.get_event_full_by_uuid(uuid)

    with {:ok, %Event{} = event} <- Events.update_event(event, event_params) do
      render(conn, "show_simple.json", event: event)
    end
  end

  def delete(conn, %{"uuid" => uuid}) do
    with event <- Events.get_event_by_uuid(uuid),
      {:ok, %Event{}} <- Events.delete_event(event) do
      send_resp(conn, :no_content, "")
    end
  end
end
