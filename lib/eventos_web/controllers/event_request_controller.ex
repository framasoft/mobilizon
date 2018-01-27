defmodule EventosWeb.EventRequestController do
  @moduledoc """
  Controller for Event requests
  """
  use EventosWeb, :controller

  alias Eventos.Events
  alias Eventos.Events.{Event, Request, Participant}
  import Logger

  action_fallback EventosWeb.FallbackController

  def index_for_account(conn, %{"id" => account_id}) do
    logged_account_id = Guardian.Plug.current_resource(conn).account.id
    if {logged_account_id, ""} == Integer.parse(account_id) do
      requests = Events.list_requests_for_account_id(logged_account_id)
      render(conn, "index.json", event_requests: requests)
    else
      send_resp(conn, :unauthorized, "")
    end
  end

  def create(conn, %{"request" => request_params}) do
    request_params = Map.put(request_params, "account_id", Guardian.Plug.current_resource(conn).account.id)

    with event <- Events.get_event!(request_params["event_id"]) do
      case event.accept do
        0 -> # If the event is opened to everyone we just add the account to the event
          with {:ok, %Participant{} = participant} <- Events.create_participant(%{"event_id" => event.id, "account_id" => request_params["account_id"]}) do
            conn
            |> put_status(:created)
            |> put_resp_header("location", participant_path(conn, :show, participant))
            |> render("show.json", participant: participant)
          end
        1 -> # If the event needs a request we create the request
          with {:ok, %Request{} = request} <- Events.create_request(request_params) do
            conn
            |> put_status(:created)
            |> put_resp_header("location", event_request_path(conn, :show, request))
            |> render("show.json", request: request)
          end
        2 -> # If the event is on invite-only we just reply nothing
          send_resp(conn, :not_found, "")
      end
    end
  end

  def create_for_event(conn, %{"request" => request_params, "id" => event_id}) do
    request_params = Map.put(request_params, "event_id", event_id)
    create(conn, request_params)
  end

  def show(conn, %{"id" => id}) do
    request = Events.get_request!(id)
    render(conn, "show.json", request: request)
  end

  def delete(conn, %{"id" => id}) do
    request = Events.get_request!(id)
    with {:ok, %Request{}} <- Events.delete_request(request) do
      send_resp(conn, :no_content, "")
    end
  end
end
