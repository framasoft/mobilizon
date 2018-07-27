# defmodule EventosWeb.EventRequestController do
#  @moduledoc """
#  Controller for Event requests
#  """
#  use EventosWeb, :controller
#
#  alias Eventos.Events
#  alias Eventos.Events.{Event, Request}
#
#  action_fallback EventosWeb.FallbackController
#
#  def index_for_user(conn, _params) do
#    actor = Guardian.Plug.current_resource(conn).actor
#    requests = Events.list_requests_for_actor(actor)
#    render(conn, "index.json", requests: requests)
#  end
#
#  def create(conn, %{"request" => request_params}) do
#    request_params = Map.put(request_params, "actor_id", Guardian.Plug.current_resource(conn).actor.id)
#    with {:ok, %Request{} = request} <- Events.create_request(request_params) do
#      conn
#      |> put_status(:created)
#      |> put_resp_header("location", event_request_path(conn, :show, request))
#      |> render("show.json", request: request)
#    end
#  end
#
#  def create_for_event(conn, %{"request" => request_params, "id" => event_id}) do
#    request_params = Map.put(request_params, "event_id", event_id)
#    create(conn, request_params)
#  end
#
#  def show(conn, %{"id" => id}) do
#    request = Events.get_request!(id)
#    render(conn, "show.json", request: request)
#  end
#
#  def update(conn, %{"id" => id, "request" => request_params}) do
#    request = Events.get_request!(id)
#
#    with {:ok, %Request{} = request} <- Events.update_request(request, request_params) do
#      render(conn, "show.json", request: request)
#    end
#  end
#
#  def delete(conn, %{"id" => id}) do
#    request = Events.get_request!(id)
#    with {:ok, %Request{}} <- Events.delete_request(request) do
#      send_resp(conn, :no_content, "")
#    end
#  end
# end
