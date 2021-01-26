# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.MediaProxyControllerTest do
  use Mobilizon.Web.ConnCase
  use Mobilizon.Tests.Helpers

  import Mock

  alias Mobilizon.Web.MediaProxy
  alias Plug.Conn

  describe "Media Proxy" do
    setup do
      clear_config([:media_proxy, :enabled], true)
      clear_config([Mobilizon.Web.Endpoint, :secret_key_base], "00000000000")

      [url: MediaProxy.encode_url("https://google.fn/test.png")]
    end

    test "it returns 404 when disabled", %{conn: conn} do
      clear_config([:media_proxy, :enabled], false)

      assert %Conn{
               status: 404,
               resp_body: "Not Found"
             } = get(conn, "/proxy/hhgfh/eeeee")

      assert %Conn{
               status: 404,
               resp_body: "Not Found"
             } = get(conn, "/proxy/hhgfh/eeee/fff")
    end

    test "it returns 403 for invalid signature", %{conn: conn, url: url} do
      Mobilizon.Config.put([Mobilizon.Web.Endpoint, :secret_key_base], "000")
      %{path: path} = URI.parse(url)

      assert %Conn{
               status: 403,
               resp_body: "Forbidden"
             } = get(conn, path)

      assert %Conn{
               status: 403,
               resp_body: "Forbidden"
             } = get(conn, "/proxy/hhgfh/eeee")

      assert %Conn{
               status: 403,
               resp_body: "Forbidden"
             } = get(conn, "/proxy/hhgfh/eeee/fff")
    end

    test "redirects to valid url when filename is invalidated", %{conn: conn, url: url} do
      invalid_url = String.replace(url, "test.png", "test-file.png")
      response = get(conn, invalid_url)
      assert response.status == 302
      assert redirected_to(response) == url
    end

    test "it performs ReverseProxy.call with valid signature", %{conn: conn, url: url} do
      with_mock Mobilizon.Web.ReverseProxy,
        call: fn _conn, _url, _opts -> %Conn{status: :success} end do
        assert %Conn{status: :success} = get(conn, url)
      end
    end
  end
end
