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
      {"x-xss-protection", "0"},
      {"x-frame-options", "DENY"},
      {"x-content-type-options", "nosniff"},
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

  @img_src "img-src 'self' data: blob: "
  @media_src "media-src 'self' "
  # Connect-src is available for any origin (*) because of webfinger query to redirect to content
  @connect_src "connect-src 'self' * blob: "
  # unsafe-eval is because of JS issues with regenerator-runtime
  # unsafe-inline will be overriten in prod with sha256 hash
  @script_src "script-src 'self' 'unsafe-eval' 'unsafe-inline' "
  @style_src "style-src 'self' "
  @font_src "font-src 'self' "

  defp csp_string do
    scheme = Config.get([Pleroma.Web.Endpoint, :url])[:scheme]
    static_url = Mobilizon.Web.Endpoint.static_url()
    websocket_url = Mobilizon.Web.Endpoint.websocket_url()

    img_src = [@img_src | get_csp_config(:img_src)]

    media_src = [@media_src | get_csp_config(:media_src)]

    connect_src = [
      @connect_src,
      static_url,
      ?\s,
      websocket_url,
      ?\s,
      get_csp_config(:connect_src)
    ]

    script_src =
      if Config.get(:env) == :dev do
        @script_src
      else
        [
          @script_src,
          "'sha256-4RS22DYeB7U14dra4KcQYxmwt5HkOInieXK1NUMBmQI=' "
        ]
      end

    script_src = [script_src | get_csp_config(:script_src)]

    style_src = [@style_src | get_csp_config(:style_src)]

    font_src = [@font_src | get_csp_config(:font_src)]

    frame_src = if Config.get(:env) == :dev, do: "frame-src 'self' ", else: "frame-src 'none' "
    frame_src = [frame_src | get_csp_config(:frame_src)]

    frame_ancestors =
      if Config.get(:env) == :dev, do: "frame-ancestors 'self' ", else: "frame-ancestors 'none' "

    frame_ancestors = [frame_ancestors | get_csp_config(:frame_ancestors)]

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
    |> to_string()
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

  defp get_csp_config(type),
    do: [:http_security, :csp_policy, type] |> Config.get() |> Enum.join(" ")
end
