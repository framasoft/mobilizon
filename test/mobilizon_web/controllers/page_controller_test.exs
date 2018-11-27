defmodule MobilizonWeb.PageControllerTest do
  use MobilizonWeb.ConnCase
  import Mobilizon.Factory

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200)
  end

  test "GET /@actor", %{conn: conn} do
    actor = insert(:actor)
    conn = get(conn, "/@#{actor.preferred_username}")
    assert html_response(conn, 200)
  end
end
