# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.HTTPSecurityPlugTest do
  use Mobilizon.Web.ConnCase
  use Mobilizon.Tests.Helpers

  alias Plug.Conn

  describe "http security enabled" do
    setup do: clear_config([:http_security, :enabled], true)

    test "it sends CSP headers when enabled", %{conn: conn} do
      conn = post(conn, "/api")

      refute Conn.get_resp_header(conn, "x-xss-protection") == []
      refute Conn.get_resp_header(conn, "x-frame-options") == []
      refute Conn.get_resp_header(conn, "x-content-type-options") == []
      refute Conn.get_resp_header(conn, "referrer-policy") == []
      refute Conn.get_resp_header(conn, "content-security-policy") == []
    end

    test "it sends STS headers when enabled", %{conn: conn} do
      clear_config([:http_security, :sts], true)

      conn = post(conn, "/api")

      refute Conn.get_resp_header(conn, "strict-transport-security") == []
    end

    test "it does not send STS headers when disabled", %{conn: conn} do
      clear_config([:http_security, :sts], false)

      conn = post(conn, "/api")

      assert Conn.get_resp_header(conn, "strict-transport-security") == []
    end

    test "referrer-policy header reflects configured value", %{conn: conn} do
      resp = post(conn, "/api")

      assert Conn.get_resp_header(resp, "referrer-policy") == ["same-origin"]

      clear_config([:http_security, :referrer_policy], "no-referrer")

      resp = post(conn, "/api")

      assert Conn.get_resp_header(resp, "referrer-policy") == ["no-referrer"]
    end

    test "default values for content-security-policy are always included", %{conn: conn} do
      conn = post(conn, "/api")

      [csp] = Conn.get_resp_header(conn, "content-security-policy")
      assert csp =~ "media-src 'self'"
      assert csp =~ "img-src 'self' data: blob: *.tile.openstreetmap.org"
      assert csp =~ "frame-src 'none'"
      assert csp =~ "frame-ancestors 'none'"
      assert csp =~ "font-src 'self'"
    end
  end

  describe "custom csp config" do
    test "it doesn't override default values", %{conn: conn} do
      clear_config([:http_security, :csp_policy, :script_src], [
        "example.com",
        "matomo.example.com"
      ])

      conn = post(conn, "/api")

      [csp] = Conn.get_resp_header(conn, "content-security-policy")

      assert csp =~
               ~r/script-src 'self' 'unsafe-eval' 'unsafe-inline' 'sha256-[\w+\/=]*' example.com matomo.example.com;/
    end
  end

  test "it does not send CSP headers when disabled", %{conn: conn} do
    clear_config([:http_security, :enabled], false)

    conn = post(conn, "/api")

    assert Conn.get_resp_header(conn, "x-xss-protection") == []
    assert Conn.get_resp_header(conn, "x-permitted-cross-domain-policies") == []
    assert Conn.get_resp_header(conn, "x-frame-options") == []
    assert Conn.get_resp_header(conn, "x-content-type-options") == []
    assert Conn.get_resp_header(conn, "x-download-options") == []
    assert Conn.get_resp_header(conn, "referrer-policy") == []
    assert Conn.get_resp_header(conn, "content-security-policy") == []
  end
end
