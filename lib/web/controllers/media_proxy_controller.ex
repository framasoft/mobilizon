# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.MediaProxyController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Config
  alias Mobilizon.Web.{MediaProxy, ReverseProxy}
  alias Plug.Conn

  # sobelow_skip ["XSS.SendResp"]
  def remote(conn, %{"sig" => sig64, "url" => url64}) do
    with {_, true} <- {:enabled, MediaProxy.enabled?()},
         {:ok, url} <- MediaProxy.decode_url(sig64, url64),
         :ok <- MediaProxy.verify_request_path_and_url(conn, url) do
      ReverseProxy.call(conn, url, media_proxy_opts())
    else
      {:enabled, false} ->
        send_resp(conn, 404, Conn.Status.reason_phrase(404))

      {:error, :invalid_signature} ->
        send_resp(conn, 403, Conn.Status.reason_phrase(403))

      {:wrong_filename, filename} ->
        redirect(conn, external: MediaProxy.build_url(sig64, url64, filename))
    end
  end

  defp media_proxy_opts do
    Config.get([:media_proxy, :proxy_opts], [])
  end
end
