defmodule EventosWeb.EventRequestControllerTest do
  use EventosWeb.ConnCase
  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Events.{Event, Request, Participant}

  def account_fixture do
    insert(:account)
  end

  def event_fixture do
    insert(:event)
  end

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all event requests for an account", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = get conn, event_request_path(conn, :index_for_account, user.account.id)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create an event request" do
    test "create an event request with valid data", %{conn: conn, user: user} do
      event = event_fixture()
      conn = auth_conn(conn, user)
      conn = post conn, event_request_path(conn, :create, request: %{"event_id" => event.id, "account_id" => user.account.id})
      assert json_response(conn, 200)["data"] == []
    end
  end

  defp auth_conn(conn, %Eventos.Accounts.User{} = user) do
    {:ok, token, _claims} = EventosWeb.Guardian.encode_and_sign(user)
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> put_req_header("accept", "application/json")
  end
end
