defmodule MobilizonWeb.PageControllerTest do
  use MobilizonWeb.ConnCase
  import Mobilizon.Factory
  alias Mobilizon.Actors.Actor
  alias MobilizonWeb.Router.Helpers, as: Routes
  alias MobilizonWeb.Endpoint

  setup do
    conn = build_conn() |> put_req_header("accept", "text/html")
    {:ok, conn: conn}
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200)
  end

  test "GET /@actor with existing actor", %{conn: conn} do
    actor = insert(:actor)
    conn = get(conn, Actor.build_url(actor.preferred_username, :page))
    assert html_response(conn, 200)
  end

  test "GET /@actor with not existing actor", %{conn: conn} do
    conn = get(conn, Actor.build_url("not_existing", :page))
    assert html_response(conn, 404)
  end

  test "GET /events/:uuid", %{conn: conn} do
    event = insert(:event)
    conn = get(conn, Routes.page_url(Endpoint, :event, event.uuid))
    assert html_response(conn, 200)
  end

  test "GET /events/:uuid with not existing event", %{conn: conn} do
    conn = get(conn, Routes.page_url(Endpoint, :event, "not_existing_event"))
    assert html_response(conn, 404)
  end

  test "GET /events/:uuid with event not public", %{conn: conn} do
    event = insert(:event, visibility: :restricted)
    conn = get(conn, Routes.page_url(Endpoint, :event, event.uuid))
    assert html_response(conn, 404)
  end

  # TODO: Comments
end
