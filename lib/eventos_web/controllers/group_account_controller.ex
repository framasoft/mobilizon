defmodule EventosWeb.GroupAccountController do
  use EventosWeb, :controller

  alias Eventos.Accounts
  alias Eventos.Accounts.GroupAccount

  def index(conn, _params) do
    group_accounts = Accounts.list_group_accounts()
    render(conn, "index.html", group_accounts: group_accounts)
  end

  def new(conn, _params) do
    changeset = Accounts.change_group_account(%GroupAccount{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"group_account" => group_account_params}) do
    case Accounts.create_group_account(group_account_params) do
      {:ok, group_account} ->
        conn
        |> put_flash(:info, "Group account created successfully.")
        |> redirect(to: group_account_path(conn, :show, group_account))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    group_account = Accounts.get_group_account!(id)
    render(conn, "show.html", group_account: group_account)
  end

  def edit(conn, %{"id" => id}) do
    group_account = Accounts.get_group_account!(id)
    changeset = Accounts.change_group_account(group_account)
    render(conn, "edit.html", group_account: group_account, changeset: changeset)
  end

  def update(conn, %{"id" => id, "group_account" => group_account_params}) do
    group_account = Accounts.get_group_account!(id)

    case Accounts.update_group_account(group_account, group_account_params) do
      {:ok, group_account} ->
        conn
        |> put_flash(:info, "Group account updated successfully.")
        |> redirect(to: group_account_path(conn, :show, group_account))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", group_account: group_account, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    group_account = Accounts.get_group_account!(id)
    {:ok, _group_account} = Accounts.delete_group_account(group_account)

    conn
    |> put_flash(:info, "Group account deleted successfully.")
    |> redirect(to: group_account_path(conn, :index))
  end
end
