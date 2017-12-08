defmodule EventosWeb.EventRequestController do
  use EventosWeb, :controller

  alias Eventos.Events
  alias Eventos.Events.EventRequest

  def index(conn, _params) do
    event_requests = Events.list_event_requests()
    render(conn, "index.html", event_requests: event_requests)
  end

  def new(conn, _params) do
    changeset = Events.change_event_request(%EventRequest{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"event_request" => event_request_params}) do
    case Events.create_event_request(event_request_params) do
      {:ok, event_request} ->
        conn
        |> put_flash(:info, "Event request created successfully.")
        |> redirect(to: event_request_path(conn, :show, event_request))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    event_request = Events.get_event_request!(id)
    render(conn, "show.html", event_request: event_request)
  end

  def edit(conn, %{"id" => id}) do
    event_request = Events.get_event_request!(id)
    changeset = Events.change_event_request(event_request)
    render(conn, "edit.html", event_request: event_request, changeset: changeset)
  end

  def update(conn, %{"id" => id, "event_request" => event_request_params}) do
    event_request = Events.get_event_request!(id)

    case Events.update_event_request(event_request, event_request_params) do
      {:ok, event_request} ->
        conn
        |> put_flash(:info, "Event request updated successfully.")
        |> redirect(to: event_request_path(conn, :show, event_request))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", event_request: event_request, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    event_request = Events.get_event_request!(id)
    {:ok, _event_request} = Events.delete_event_request(event_request)

    conn
    |> put_flash(:info, "Event request deleted successfully.")
    |> redirect(to: event_request_path(conn, :index))
  end
end
