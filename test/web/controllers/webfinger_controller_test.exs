# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/web_finger/web_finger_test.exs

defmodule Mobilizon.Web.WebFingerControllerTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.WebFinger

  alias Mobilizon.Web.Endpoint

  setup_all do
    Mobilizon.Config.put([:instance, :federating], true)

    :ok
  end

  test "GET /.well-known/host-meta", %{conn: conn} do
    conn = get(conn, "/.well-known/host-meta")

    assert response(conn, 200) ==
             "<?xml version=\"1.0\" encoding=\"UTF-8\"?><XRD xmlns=\"http://docs.oasis-open.org/ns/xri/xrd-1.0\"><Link rel=\"lrdd\" template=\"#{
               Endpoint.url()
             }/.well-known/webfinger?resource={uri}\" type=\"application/xrd+xml\" /></XRD>"

    assert {"content-type", "application/xrd+xml; charset=utf-8"} in conn.resp_headers
  end

  test "GET /.well-known/webfinger with local actor", %{conn: conn} do
    %Actor{preferred_username: username} = actor = insert(:actor)
    conn = get(conn, "/.well-known/webfinger?resource=acct:#{username}@mobilizon.test")
    assert json_response(conn, 200) == WebFinger.represent_actor(actor)
  end

  test "GET /.well-known/webfinger with non existent actor", %{conn: conn} do
    conn = get(conn, "/.well-known/webfinger?resource=acct:notme@mobilizon.test")
    assert response(conn, 404) == "Couldn't find user"
  end

  test "GET /.well-known/webfinger with no query", %{conn: conn} do
    conn = get(conn, "/.well-known/webfinger")
    assert response(conn, 400) == "No query provided"
  end
end
