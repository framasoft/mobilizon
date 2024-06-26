# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Plugs.HTTPSecurityPlug do
  @moduledoc """
  A plug to setup some HTTP security-related headers, like CSP
  """

  alias Mobilizon.Config
  alias Mobilizon.Service.{FrontEndAnalytics, GlobalSearch, Pictures}
  alias Mobilizon.Web.Endpoint
  import Plug.Conn

  require Logger

  @spec init(any()) :: any()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, options \\ []) do
    if Config.get([:http_security, :enabled]) do
      conn
      |> merge_resp_headers(headers(options))
      |> maybe_send_sts_header(Config.get([:http_security, :sts], false))
    else
      conn
    end
  end

  @spec headers(Keyword.t()) :: list({String.t(), String.t()})
  defp headers(options) do
    referrer_policy =
      Keyword.get(options, :referrer_policy, Config.get([:http_security, :referrer_policy]))

    report_uri = Config.get([:http_security, :report_uri])

    headers = [
      {"x-xss-protection", "0"},
      {"x-frame-options", "DENY"},
      {"x-content-type-options", "nosniff"},
      {"referrer-policy", referrer_policy},
      {"content-security-policy", csp_string(options)}
    ]

    if report_uri do
      report_group = %{
        "group" => "csp-endpoint",
        "max-age" => 10_886_400,
        "endpoints" => [
          %{"url" => report_uri}
        ]
      }

      [
        {"report-to", Jason.encode!(report_group)},
        {"reporting-endpoints", "csp-endpoint=\"#{report_uri}\""} | headers
      ]
    else
      headers
    end
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
  @script_src "script-src 'self' 'unsafe-eval' "
  @style_src "style-src 'self' "
  @font_src "font-src 'self' data: "

  @spec csp_string(Keyword.t()) :: String.t()
  defp csp_string(options) do
    scheme = Keyword.get(options, :scheme, Config.get([Endpoint, :url])[:scheme])
    static_url = Endpoint.static_url()
    websocket_url = Endpoint.websocket_url()
    report_uri = Config.get([:http_security, :report_uri])

    img_src = [@img_src] ++ [get_csp_config(:img_src, options)]

    media_src = [@media_src] ++ [get_csp_config(:media_src, options)]

    connect_src = [
      @connect_src,
      static_url,
      ?\s,
      websocket_url,
      ?\s,
      get_csp_config(:connect_src, options)
    ]

    script_src =
      if Config.get(:env) == :dev do
        [@script_src, "'unsafe-inline' "]
      else
        [
          @script_src,
          "'sha256-4RS22DYeB7U14dra4KcQYxmwt5HkOInieXK1NUMBmQI=' ",
          "'sha256-zJdRXhLWm9NGI6BFr+sNmHBBrjAdJdFr7MpUq0EwK58=' "
        ]
      end

    script_src = [script_src] ++ [get_csp_config(:script_src, options)]

    style_src =
      if Config.get(:env) == :dev, do: [@style_src | "'unsafe-inline' "], else: @style_src

    style_src = [style_src] ++ [get_csp_config(:style_src, options)]

    style_src = [style_src] ++ ["'sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU='"]

    font_src = [@font_src] ++ [get_csp_config(:font_src, options)]

    frame_src = build_csp_field(:frame_src, options)
    frame_ancestors = build_csp_field(:frame_ancestors, options)

    report = if report_uri, do: ["report-uri ", report_uri, " ; report-to csp-endpoint"]
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
    |> add_csp_param(report)
    |> to_string()
  end

  @spec add_csp_param(iodata(), iodata() | nil) :: list()
  defp add_csp_param(csp_iodata, nil), do: csp_iodata
  defp add_csp_param(csp_iodata, param), do: [[param, ?;] | csp_iodata]

  @spec maybe_send_sts_header(Plug.Conn.t(), boolean()) :: Plug.Conn.t()
  defp maybe_send_sts_header(conn, true) do
    max_age_sts = Config.get([:http_security, :sts_max_age])

    merge_resp_headers(conn, [
      {"strict-transport-security", "max-age=#{max_age_sts}; includeSubDomains"}
    ])
  end

  defp maybe_send_sts_header(conn, false), do: conn

  @spec get_csp_config(atom(), Keyword.t()) :: iodata()
  defp get_csp_config(type, options) do
    config_policy = Keyword.get(options, type, Config.get([:http_security, :csp_policy, type]))
    front_end_analytics_policy = Keyword.get(FrontEndAnalytics.csp(), type, [])
    global_search_policy = Keyword.get(GlobalSearch.service().csp(), type, [])
    pictures_policy = Keyword.get(Pictures.service().csp(), type, [])

    resource_providers = Config.get([Mobilizon.Service.ResourceProviders, :csp_policy, type], [])

    Enum.join(
      config_policy ++
        front_end_analytics_policy ++
        global_search_policy ++ pictures_policy ++ resource_providers,
      " "
    )
  end

  defp build_csp_field(type, options) do
    csp_config = get_csp_config(type, options)

    csp_config =
      if Config.get(:env) == :dev do
        [csp_config] ++ ["'self'"]
      else
        if csp_config == "" do
          ["'none'"]
        else
          [csp_config]
        end
      end

    Enum.join([type |> to_string() |> String.replace("_", "-")] ++ csp_config, " ")
  end
end
