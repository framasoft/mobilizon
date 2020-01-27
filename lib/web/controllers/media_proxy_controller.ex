# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/media_proxy/controller.ex

defmodule Mobilizon.Web.MediaProxyController do
  use Mobilizon.Web, :controller

  alias Plug.Conn

  alias Mobilizon.Config

  alias Mobilizon.Web.MediaProxy
  alias Mobilizon.Web.ReverseProxy

  @default_proxy_opts [max_body_length: 25 * 1_048_576, http: [follow_redirect: true]]

  def remote(conn, %{"sig" => sig64, "url" => url64} = params) do
    with config <- Config.get([:media_proxy], []),
         true <- Keyword.get(config, :enabled, false),
         {:ok, url} <- MediaProxy.decode_url(sig64, url64),
         :ok <- filename_matches(Map.has_key?(params, "filename"), conn.request_path, url) do
      ReverseProxy.call(conn, url, Keyword.get(config, :proxy_opts, @default_proxy_opts))
    else
      false ->
        send_resp(conn, 404, Conn.Status.reason_phrase(404))

      {:error, :invalid_signature} ->
        send_resp(conn, 403, Conn.Status.reason_phrase(403))

      {:wrong_filename, filename} ->
        redirect(conn, external: MediaProxy.build_url(sig64, url64, filename))
    end
  end

  def filename_matches(has_filename, path, url) do
    filename =
      url
      |> MediaProxy.filename()
      |> URI.decode()

    path = URI.decode(path)

    if has_filename && filename && Path.basename(path) != filename do
      {:wrong_filename, filename}
    else
      :ok
    end
  end
end
