defmodule EventosWeb.GroupAccountControllerTest do
  use EventosWeb.ConnCase

  alias Eventos.Accounts

  @create_attrs %{role: 42}
  @update_attrs %{role: 43}
  @invalid_attrs %{role: nil}

  def fixture(:group_account) do
    {:ok, group_account} = Accounts.create_group_account(@create_attrs)
    group_account
  end

  describe "index" do
    test "lists all group_accounts", %{conn: conn} do
      conn = get conn, group_account_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Group accounts"
    end
  end

  describe "new group_account" do
    test "renders form", %{conn: conn} do
      conn = get conn, group_account_path(conn, :new)
      assert html_response(conn, 200) =~ "New Group account"
    end
  end

  describe "create group_account" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, group_account_path(conn, :create), group_account: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == group_account_path(conn, :show, id)

      conn = get conn, group_account_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Group account"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, group_account_path(conn, :create), group_account: @invalid_attrs
      assert html_response(conn, 200) =~ "New Group account"
    end
  end

  describe "edit group_account" do
    setup [:create_group_account]

    test "renders form for editing chosen group_account", %{conn: conn, group_account: group_account} do
      conn = get conn, group_account_path(conn, :edit, group_account)
      assert html_response(conn, 200) =~ "Edit Group account"
    end
  end

  describe "update group_account" do
    setup [:create_group_account]

    test "redirects when data is valid", %{conn: conn, group_account: group_account} do
      conn = put conn, group_account_path(conn, :update, group_account), group_account: @update_attrs
      assert redirected_to(conn) == group_account_path(conn, :show, group_account)

      conn = get conn, group_account_path(conn, :show, group_account)
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, group_account: group_account} do
      conn = put conn, group_account_path(conn, :update, group_account), group_account: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Group account"
    end
  end

  describe "delete group_account" do
    setup [:create_group_account]

    test "deletes chosen group_account", %{conn: conn, group_account: group_account} do
      conn = delete conn, group_account_path(conn, :delete, group_account)
      assert redirected_to(conn) == group_account_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, group_account_path(conn, :show, group_account)
      end
    end
  end

  defp create_group_account(_) do
    group_account = fixture(:group_account)
    {:ok, group_account: group_account}
  end
end
