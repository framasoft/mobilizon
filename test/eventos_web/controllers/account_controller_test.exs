defmodule EventosWeb.AccountControllerTest do
  use EventosWeb.ConnCase

  alias Eventos.Accounts

  @create_attrs %{description: "some description", display_name: "some display_name", domain: "some domain", private_key: "some private_key", public_key: "some public_key", suspended: true, uri: "some uri", url: "some url", username: "some username"}
  @update_attrs %{description: "some updated description", display_name: "some updated display_name", domain: "some updated domain", private_key: "some updated private_key", public_key: "some updated public_key", suspended: false, uri: "some updated uri", url: "some updated url", username: "some updated username"}
  @invalid_attrs %{description: nil, display_name: nil, domain: nil, private_key: nil, public_key: nil, suspended: nil, uri: nil, url: nil, username: nil}

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(@create_attrs)
    account
  end

  describe "index" do
    test "lists all accounts", %{conn: conn} do
      conn = get conn, account_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Accounts"
    end
  end

  describe "new account" do
    test "renders form", %{conn: conn} do
      conn = get conn, account_path(conn, :new)
      assert html_response(conn, 200) =~ "New Account"
    end
  end

  describe "create account" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, account_path(conn, :create), account: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == account_path(conn, :show, id)

      conn = get conn, account_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Account"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, account_path(conn, :create), account: @invalid_attrs
      assert html_response(conn, 200) =~ "New Account"
    end
  end

  describe "edit account" do
    setup [:create_account]

    test "renders form for editing chosen account", %{conn: conn, account: account} do
      conn = get conn, account_path(conn, :edit, account)
      assert html_response(conn, 200) =~ "Edit Account"
    end
  end

  describe "update account" do
    setup [:create_account]

    test "redirects when data is valid", %{conn: conn, account: account} do
      conn = put conn, account_path(conn, :update, account), account: @update_attrs
      assert redirected_to(conn) == account_path(conn, :show, account)

      conn = get conn, account_path(conn, :show, account)
      assert html_response(conn, 200) =~ "some updated description"
    end

    test "renders errors when data is invalid", %{conn: conn, account: account} do
      conn = put conn, account_path(conn, :update, account), account: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Account"
    end
  end

  describe "delete account" do
    setup [:create_account]

    test "deletes chosen account", %{conn: conn, account: account} do
      conn = delete conn, account_path(conn, :delete, account)
      assert redirected_to(conn) == account_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, account_path(conn, :show, account)
      end
    end
  end

  defp create_account(_) do
    account = fixture(:account)
    {:ok, account: account}
  end
end
