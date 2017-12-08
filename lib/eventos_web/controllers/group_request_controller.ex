defmodule EventosWeb.GroupRequestController do
  use EventosWeb, :controller

  alias Eventos.Accounts
  alias Eventos.Accounts.GroupRequest

  def index(conn, _params) do
    group_request = Accounts.list_group_requests()
    render(conn, "index.html", group_request: group_request)
  end

  def new(conn, _params) do
    changeset = Accounts.change_group_request(%GroupRequest{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"group_request" => group_request_params}) do
    case Accounts.create_group_request(group_request_params) do
      {:ok, group_request} ->
        conn
        |> put_flash(:info, "Group request created successfully.")
        |> redirect(to: group_request_path(conn, :show, group_request))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    group_request = Accounts.get_group_request!(id)
    render(conn, "show.html", group_request: group_request)
  end

  def edit(conn, %{"id" => id}) do
    group_request = Accounts.get_group_request!(id)
    changeset = Accounts.change_group_request(group_request)
    render(conn, "edit.html", group_request: group_request, changeset: changeset)
  end

  def update(conn, %{"id" => id, "group_request" => group_request_params}) do
    group_request = Accounts.get_group_request!(id)

    case Accounts.update_group_request(group_request, group_request_params) do
      {:ok, group_request} ->
        conn
        |> put_flash(:info, "Group request updated successfully.")
        |> redirect(to: group_request_path(conn, :show, group_request))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", group_request: group_request, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    group_request = Accounts.get_group_request!(id)
    {:ok, _group_request} = Accounts.delete_group_request(group_request)

    conn
    |> put_flash(:info, "Group request deleted successfully.")
    |> redirect(to: group_request_path(conn, :index))
  end
end
