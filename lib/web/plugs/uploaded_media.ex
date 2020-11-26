# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/plugs/uploaded_media.ex

defmodule Mobilizon.Web.Plugs.UploadedMedia do
  @moduledoc """
  Serves uploaded media files
  """

  @behaviour Plug

  import Plug.Conn

  alias Mobilizon.Config

  alias Mobilizon.Web.{ReverseProxy, Upload}

  require Logger

  # no slashes
  @path "media"

  def init(_opts) do
    static_plug_opts =
      []
      |> Keyword.put(:from, "__unconfigured_media_plug")
      |> Keyword.put(:at, "/__unconfigured_media_plug")
      |> Plug.Static.init()

    %{static_plug_opts: static_plug_opts}
  end

  def call(%{request_path: <<"/", @path, "/", file::binary>>} = conn, opts) do
    conn =
      case fetch_query_params(conn) do
        %{query_params: %{"name" => name}} = conn ->
          name = String.replace(name, "\"", "\\\"")

          put_resp_header(conn, "content-disposition", "filename=\"#{name}\"")

        conn ->
          conn
      end

    config = Config.get([Upload])

    with uploader <- Keyword.fetch!(config, :uploader),
         proxy_remote = Keyword.get(config, :proxy_remote, false),
         {:ok, get_method} <- uploader.get_file(file) do
      get_media(conn, get_method, proxy_remote, opts)
    else
      _ ->
        conn
        |> send_resp(500, "Failed")
        |> halt()
    end
  end

  def call(conn, _opts), do: conn

  defp get_media(conn, {:static_dir, directory}, _, opts) do
    static_opts =
      opts
      |> Map.get(:static_plug_opts)
      |> Map.put(:at, [@path])
      |> Map.put(:from, directory)

    conn = Plug.Static.call(conn, static_opts)

    if conn.halted do
      conn
    else
      conn
      |> delete_resp_header("content-disposition")
      |> put_status(404)
      |> Phoenix.Controller.put_view(Mobilizon.Web.ErrorView)
      |> Phoenix.Controller.render("404.html")
      |> halt()
    end
  end

  defp get_media(conn, {:url, url}, true, _) do
    ReverseProxy.call(conn, url, Config.get([Mobilizon.Upload, :proxy_opts], []))
  end

  defp get_media(conn, {:url, url}, _, _) do
    conn
    |> Phoenix.Controller.redirect(external: url)
    |> halt()
  end

  defp get_media(conn, unknown, _, _) do
    Logger.error("#{__MODULE__}: Unknown get startegy: #{inspect(unknown)}")

    conn
    |> send_resp(500, "Internal Error")
    |> halt()
  end
end
