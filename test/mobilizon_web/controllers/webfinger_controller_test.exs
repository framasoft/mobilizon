defmodule MobilizonWeb.WebFingerTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.WebFinger
  import Mobilizon.Factory

  test "GET /.well-known/host-meta", %{conn: conn} do
    conn = get(conn, "/.well-known/host-meta")

    assert response(conn, 200) ==
             "<?xml version=\"1.0\" encoding=\"UTF-8\"?><XRD xmlns=\"http://docs.oasis-open.org/ns/xri/xrd-1.0\"><Link rel=\"lrdd\" template=\"#{
               MobilizonWeb.Endpoint.url()
             }/.well-known/webfinger?resource={uri}\" type=\"application/xrd+xml\" /></XRD>"

    assert {"content-type", "application/xrd+xml; charset=utf-8"} in conn.resp_headers
  end

  test "GET /.well-known/webfinger with local actor", %{conn: conn} do
    %Actor{preferred_username: username} = actor = insert(:actor)
    conn = get(conn, "/.well-known/webfinger?resource=acct:#{username}@localhost:4001")
    assert json_response(conn, 200) == WebFinger.represent_actor(actor)
  end

  test "GET /.well-known/webfinger with no query", %{conn: conn} do
    conn = get(conn, "/.well-known/webfinger")
    assert response(conn, 400) == "No query provided"
  end
end
