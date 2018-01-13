defmodule EventosWeb.AccountControllerTest do
  use EventosWeb.ConnCase

  import Eventos.Factory

  alias Eventos.Accounts

  @create_attrs %{description: "some description", display_name: "some display_name", domain: "some domain", private_key: "some private_key", public_key: "some public_key", suspended: true, uri: "some uri", url: "some url", username: "some username"}
  @update_attrs %{description: "some updated description", display_name: "some updated display_name", domain: "some updated domain", private_key: "some updated private_key", public_key: "some updated public_key", suspended: false, uri: "some updated uri", url: "some updated url", username: "some updated username"}
  @invalid_attrs %{description: nil, display_name: nil, domain: nil, private_key: nil, public_key: nil, suspended: nil, uri: nil, url: nil, username: nil}

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(@create_attrs)
    account
  end

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all accounts", %{conn: conn, user: user} do
      conn = get conn, account_path(conn, :index)
      assert hd(json_response(conn, 200)["data"])["username"] == user.account.username
    end
  end

  describe "delete account" do
    setup [:create_account]

    test "deletes own account", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = delete conn, account_path(conn, :delete, user.account)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, account_path(conn, :show, user.account)
      end
    end

    test "deletes other account", %{conn: conn, account: account, user: user} do
      conn = auth_conn(conn, user)
      conn = delete conn, account_path(conn, :delete, account)
      assert response(conn, 401)
      conn = get conn, account_path(conn, :show, account)
      assert response(conn, 200)
    end
  end

  defp create_account(_) do
    account = fixture(:account)
    {:ok, account: account}
  end

  defp auth_conn(conn, %Eventos.Accounts.User{} = user) do
    {:ok, token, _claims} = EventosWeb.Guardian.encode_and_sign(user)
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> put_req_header("accept", "application/json")
  end
end
