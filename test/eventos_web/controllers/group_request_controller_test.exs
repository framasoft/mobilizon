defmodule EventosWeb.GroupRequestControllerTest do
  use EventosWeb.ConnCase

  alias Eventos.Accounts

  @create_attrs %{state: 42}
  @update_attrs %{state: 43}
  @invalid_attrs %{state: nil}

  def fixture(:group_request) do
    {:ok, group_request} = Accounts.create_group_request(@create_attrs)
    group_request
  end

  describe "index" do
    test "lists all group_request", %{conn: conn} do
      conn = get conn, group_request_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Group requests"
    end
  end

  describe "new group_request" do
    test "renders form", %{conn: conn} do
      conn = get conn, group_request_path(conn, :new)
      assert html_response(conn, 200) =~ "New Group request"
    end
  end

  describe "create group_request" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, group_request_path(conn, :create), group_request: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == group_request_path(conn, :show, id)

      conn = get conn, group_request_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Group request"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, group_request_path(conn, :create), group_request: @invalid_attrs
      assert html_response(conn, 200) =~ "New Group request"
    end
  end

  describe "edit group_request" do
    setup [:create_group_request]

    test "renders form for editing chosen group_request", %{conn: conn, group_request: group_request} do
      conn = get conn, group_request_path(conn, :edit, group_request)
      assert html_response(conn, 200) =~ "Edit Group request"
    end
  end

  describe "update group_request" do
    setup [:create_group_request]

    test "redirects when data is valid", %{conn: conn, group_request: group_request} do
      conn = put conn, group_request_path(conn, :update, group_request), group_request: @update_attrs
      assert redirected_to(conn) == group_request_path(conn, :show, group_request)

      conn = get conn, group_request_path(conn, :show, group_request)
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, group_request: group_request} do
      conn = put conn, group_request_path(conn, :update, group_request), group_request: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Group request"
    end
  end

  describe "delete group_request" do
    setup [:create_group_request]

    test "deletes chosen group_request", %{conn: conn, group_request: group_request} do
      conn = delete conn, group_request_path(conn, :delete, group_request)
      assert redirected_to(conn) == group_request_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, group_request_path(conn, :show, group_request)
      end
    end
  end

  defp create_group_request(_) do
    group_request = fixture(:group_request)
    {:ok, group_request: group_request}
  end
end
