defmodule EventosWeb.EventAccountsControllerTest do
  use EventosWeb.ConnCase

  alias Eventos.Events

  @create_attrs %{roles: 42}
  @update_attrs %{roles: 43}
  @invalid_attrs %{roles: nil}

  def fixture(:event_accounts) do
    {:ok, event_accounts} = Events.create_event_accounts(@create_attrs)
    event_accounts
  end

  describe "index" do
    test "lists all event_accounts", %{conn: conn} do
      conn = get conn, event_accounts_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Event accounts"
    end
  end

  describe "new event_accounts" do
    test "renders form", %{conn: conn} do
      conn = get conn, event_accounts_path(conn, :new)
      assert html_response(conn, 200) =~ "New Event accounts"
    end
  end

  describe "create event_accounts" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, event_accounts_path(conn, :create), event_accounts: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == event_accounts_path(conn, :show, id)

      conn = get conn, event_accounts_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Event accounts"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, event_accounts_path(conn, :create), event_accounts: @invalid_attrs
      assert html_response(conn, 200) =~ "New Event accounts"
    end
  end

  describe "edit event_accounts" do
    setup [:create_event_accounts]

    test "renders form for editing chosen event_accounts", %{conn: conn, event_accounts: event_accounts} do
      conn = get conn, event_accounts_path(conn, :edit, event_accounts)
      assert html_response(conn, 200) =~ "Edit Event accounts"
    end
  end

  describe "update event_accounts" do
    setup [:create_event_accounts]

    test "redirects when data is valid", %{conn: conn, event_accounts: event_accounts} do
      conn = put conn, event_accounts_path(conn, :update, event_accounts), event_accounts: @update_attrs
      assert redirected_to(conn) == event_accounts_path(conn, :show, event_accounts)

      conn = get conn, event_accounts_path(conn, :show, event_accounts)
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, event_accounts: event_accounts} do
      conn = put conn, event_accounts_path(conn, :update, event_accounts), event_accounts: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Event accounts"
    end
  end

  describe "delete event_accounts" do
    setup [:create_event_accounts]

    test "deletes chosen event_accounts", %{conn: conn, event_accounts: event_accounts} do
      conn = delete conn, event_accounts_path(conn, :delete, event_accounts)
      assert redirected_to(conn) == event_accounts_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, event_accounts_path(conn, :show, event_accounts)
      end
    end
  end

  defp create_event_accounts(_) do
    event_accounts = fixture(:event_accounts)
    {:ok, event_accounts: event_accounts}
  end
end
