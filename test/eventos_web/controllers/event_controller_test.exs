defmodule EventosWeb.EventControllerTest do
  use EventosWeb.ConnCase
  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Events.Event

  @create_attrs %{begins_on: "2010-04-17 14:00:00.000000Z", description: "some description", ends_on: "2010-04-17 14:00:00.000000Z", title: "some title"}
  @update_attrs %{begins_on: "2011-05-18 15:01:01.000000Z", description: "some updated description", ends_on: "2011-05-18 15:01:01.000000Z", title: "some updated title"}
  @invalid_attrs %{begins_on: nil, description: nil, ends_on: nil, title: nil}

  def fixture(:event) do
    {:ok, event} = Events.create_event(@create_attrs)
    event
  end

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all events", %{conn: conn} do
      conn = get conn, event_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create event" do
    test "renders event when data is valid", %{conn: conn, user: user} do
      attrs = Map.put(@create_attrs, :organizer_id, user.account.id)
      conn = auth_conn(conn, user)
      conn = post conn, event_path(conn, :create), event: attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, event_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "begins_on" => "2010-04-17T14:00:00Z",
        "description" => "some description",
        "ends_on" => "2010-04-17T14:00:00Z",
        "title" => "some title"}
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      attrs = Map.put(@invalid_attrs, :organizer_id, user.account.id)
      conn = post conn, event_path(conn, :create), event: attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update event" do
    setup [:create_event]

    test "renders event when data is valid", %{conn: conn, event: %Event{id: id} = event, user: user} do
      conn = auth_conn(conn, user)
      attrs = Map.put(@update_attrs, :organizer_id, user.account.id)
      conn = put conn, event_path(conn, :update, event), event: attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, event_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "begins_on" => "2011-05-18T15:01:01Z",
        "description" => "some updated description",
        "ends_on" => "2011-05-18T15:01:01Z",
        "title" => "some updated title"}
    end

    test "renders errors when data is invalid", %{conn: conn, event: event, user: user} do
      conn = auth_conn(conn, user)
      attrs = Map.put(@invalid_attrs, :organizer_id, user.account.id)
      conn = put conn, event_path(conn, :update, event), event: attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete event" do
    setup [:create_event]

    test "deletes chosen event", %{conn: conn, event: event, user: user} do
      conn = auth_conn(conn, user)
      conn = delete conn, event_path(conn, :delete, event)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, event_path(conn, :show, event)
      end
    end
  end

  defp create_event(_) do
    account = insert(:account)
    event = insert(:event, organizer: account)
    {:ok, event: event, account: account}
  end

  defp auth_conn(conn, %Eventos.Accounts.User{} = user) do
    {:ok, token, _claims} = EventosWeb.Guardian.encode_and_sign(user)
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> put_req_header("accept", "application/json")
  end
end
