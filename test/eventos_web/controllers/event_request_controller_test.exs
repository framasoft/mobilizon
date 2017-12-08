defmodule EventosWeb.EventRequestControllerTest do
  use EventosWeb.ConnCase

  alias Eventos.Events

  @create_attrs %{state: 42}
  @update_attrs %{state: 43}
  @invalid_attrs %{state: nil}

  def fixture(:event_request) do
    {:ok, event_request} = Events.create_event_request(@create_attrs)
    event_request
  end

  describe "index" do
    test "lists all event_requests", %{conn: conn} do
      conn = get conn, event_request_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Event requests"
    end
  end

  describe "new event_request" do
    test "renders form", %{conn: conn} do
      conn = get conn, event_request_path(conn, :new)
      assert html_response(conn, 200) =~ "New Event request"
    end
  end

  describe "create event_request" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, event_request_path(conn, :create), event_request: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == event_request_path(conn, :show, id)

      conn = get conn, event_request_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Event request"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, event_request_path(conn, :create), event_request: @invalid_attrs
      assert html_response(conn, 200) =~ "New Event request"
    end
  end

  describe "edit event_request" do
    setup [:create_event_request]

    test "renders form for editing chosen event_request", %{conn: conn, event_request: event_request} do
      conn = get conn, event_request_path(conn, :edit, event_request)
      assert html_response(conn, 200) =~ "Edit Event request"
    end
  end

  describe "update event_request" do
    setup [:create_event_request]

    test "redirects when data is valid", %{conn: conn, event_request: event_request} do
      conn = put conn, event_request_path(conn, :update, event_request), event_request: @update_attrs
      assert redirected_to(conn) == event_request_path(conn, :show, event_request)

      conn = get conn, event_request_path(conn, :show, event_request)
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, event_request: event_request} do
      conn = put conn, event_request_path(conn, :update, event_request), event_request: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Event request"
    end
  end

  describe "delete event_request" do
    setup [:create_event_request]

    test "deletes chosen event_request", %{conn: conn, event_request: event_request} do
      conn = delete conn, event_request_path(conn, :delete, event_request)
      assert redirected_to(conn) == event_request_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, event_request_path(conn, :show, event_request)
      end
    end
  end

  defp create_event_request(_) do
    event_request = fixture(:event_request)
    {:ok, event_request: event_request}
  end
end
