defmodule EventosWeb.EventAccountsController do
  use EventosWeb, :controller

  alias Eventos.Events
  alias Eventos.Events.EventAccounts

  def index(conn, _params) do
    event_accounts = Events.list_event_accounts()
    render(conn, "index.html", event_accounts: event_accounts)
  end

  def new(conn, _params) do
    changeset = Events.change_event_accounts(%EventAccounts{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"event_accounts" => event_accounts_params}) do
    case Events.create_event_accounts(event_accounts_params) do
      {:ok, event_accounts} ->
        conn
        |> put_flash(:info, "Event accounts created successfully.")
        |> redirect(to: event_accounts_path(conn, :show, event_accounts))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    event_accounts = Events.get_event_accounts!(id)
    render(conn, "show.html", event_accounts: event_accounts)
  end

  def edit(conn, %{"id" => id}) do
    event_accounts = Events.get_event_accounts!(id)
    changeset = Events.change_event_accounts(event_accounts)
    render(conn, "edit.html", event_accounts: event_accounts, changeset: changeset)
  end

  def update(conn, %{"id" => id, "event_accounts" => event_accounts_params}) do
    event_accounts = Events.get_event_accounts!(id)

    case Events.update_event_accounts(event_accounts, event_accounts_params) do
      {:ok, event_accounts} ->
        conn
        |> put_flash(:info, "Event accounts updated successfully.")
        |> redirect(to: event_accounts_path(conn, :show, event_accounts))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", event_accounts: event_accounts, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    event_accounts = Events.get_event_accounts!(id)
    {:ok, _event_accounts} = Events.delete_event_accounts(event_accounts)

    conn
    |> put_flash(:info, "Event accounts deleted successfully.")
    |> redirect(to: event_accounts_path(conn, :index))
  end
end
