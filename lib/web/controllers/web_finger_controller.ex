# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/web_finger/web_finger_controller.ex

defmodule Mobilizon.Web.WebFingerController do
  @moduledoc """
  Handles Webfinger requests
  """

  use Mobilizon.Web, :controller

  alias Mobilizon.Federation.WebFinger

  plug(Mobilizon.Web.Plugs.Federating)

  @doc """
  Provides /.well-known/host-meta
  """
  def host_meta(conn, _params) do
    xml = WebFinger.host_meta()

    conn
    |> put_resp_content_type("application/xrd+xml")
    |> send_resp(200, xml)
  end

  @doc """
  Provides /.well-known/webfinger
  """
  def webfinger(conn, %{"resource" => resource}) do
    case WebFinger.webfinger(resource, "JSON") do
      {:ok, response} -> json(conn, response)
      _e -> send_resp(conn, 404, "Couldn't find user")
    end
  end

  def webfinger(conn, _), do: send_resp(conn, 400, "No query provided")
end
