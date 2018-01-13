defmodule EventosWeb.AccountController do
  use EventosWeb, :controller

  alias Eventos.Accounts
  alias Eventos.Accounts.Account
  import Logger

  action_fallback EventosWeb.FallbackController

  def index(conn, _params) do
    accounts = Accounts.list_accounts()
    render(conn, "index.json", accounts: accounts)
  end

  def show(conn, %{"id" => id}) do
    account = Accounts.get_account_with_everything!(id)
    render(conn, "show.json", account: account)
  end

  def update(conn, %{"id" => id, "account" => account_params}) do
    account = Accounts.get_account!(id)

    with {:ok, %Account{} = account} <- Accounts.update_account(account, account_params) do
      render(conn, "show.json", account: account)
    end
  end

  def delete(conn, %{"id" => id_str}) do
    {id, _} = Integer.parse(id_str)
    if Guardian.Plug.current_resource(conn).account.id == id do
      account = Accounts.get_account!(id)
      with {:ok, %Account{}} <- Accounts.delete_account(account) do
        send_resp(conn, :no_content, "")
      end
    else
      send_resp(conn, 401, "")
    end
  end
end
