# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.HTTPSecurityPlug do
  @moduledoc """
  A plug to setup some HTTP security-related headers, like CSP
  """

  alias Mobilizon.Config
  import Plug.Conn

  require Logger

  def init(opts), do: opts

  def call(conn, _options) do
    if Config.get([:http_security, :enabled]) do
      conn
      |> merge_resp_headers(headers())
      |> maybe_send_sts_header(Config.get([:http_security, :sts]))
    else
      conn
    end
  end

  defp headers do
    referrer_policy = Config.get([:http_security, :referrer_policy])

    [
      {"referrer-policy", referrer_policy},
      {"content-security-policy", csp_string()}
    ]
  end

  @static_csp_rules [
    "default-src 'none'",
    "base-uri 'self'",
    "manifest-src 'self'"
  ]

  @csp_start [Enum.join(@static_csp_rules, ";") <> ";"]

  defp csp_string do
    scheme = Config.get([Pleroma.Web.Endpoint, :url])[:scheme]
    static_url = Mobilizon.Web.Endpoint.static_url()
    websocket_url = Mobilizon.Web.Endpoint.websocket_url()

    img_src =
      ["img-src 'self' data: blob: "] ++ Config.get([:http_security, :csp_policy, :img_src])

    media_src = ["media-src 'self' "] ++ Config.get([:http_security, :csp_policy, :media_src])

    connect_src =
      ["connect-src 'self' blob: ", static_url, ?\s, websocket_url] ++
        Config.get([:http_security, :csp_policy, :connect_src])

    script_src =
      if Config.get(:env) == :dev do
        "script-src 'self' 'unsafe-eval' 'unsafe-inline' "
      else
        "script-src 'self' 'unsafe-eval' 'sha256-4RS22DYeB7U14dra4KcQYxmwt5HkOInieXK1NUMBmQI=' "
      end

    script_src = [script_src] ++ Config.get([:http_security, :csp_policy, :script_src])

    style_src =
      ["style-src 'self' 'unsafe-inline' "] ++
        Config.get([:http_security, :csp_policy, :style_src])

    font_src = ["font-src 'self' "] ++ Config.get([:http_security, :csp_policy, :font_src])

    frame_src = if Config.get(:env) == :dev, do: "frame-src 'self' ", else: "frame-src 'none' "
    frame_src = [frame_src] ++ Config.get([:http_security, :csp_policy, :frame_src])

    frame_ancestors =
      if Config.get(:env) == :dev, do: "frame-ancestors 'self' ", else: "frame-ancestors 'none' "

    frame_ancestors =
      [frame_ancestors] ++ Config.get([:http_security, :csp_policy, :frame_ancestors])

    insecure = if scheme == "https", do: "upgrade-insecure-requests"

    @csp_start
    |> add_csp_param(script_src)
    |> add_csp_param(style_src)
    |> add_csp_param(connect_src)
    |> add_csp_param(img_src)
    |> add_csp_param(media_src)
    |> add_csp_param(font_src)
    |> add_csp_param(frame_src)
    |> add_csp_param(frame_ancestors)
    |> add_csp_param(insecure)
    |> :erlang.iolist_to_binary()
  end

  defp add_csp_param(csp_iodata, nil), do: csp_iodata

  defp add_csp_param(csp_iodata, param), do: [[param, ?;] | csp_iodata]

  defp maybe_send_sts_header(conn, true) do
    max_age_sts = Config.get([:http_security, :sts_max_age])

    merge_resp_headers(conn, [
      {"strict-transport-security", "max-age=#{max_age_sts}; includeSubDomains"}
    ])
  end

  defp maybe_send_sts_header(conn, _), do: conn
end
