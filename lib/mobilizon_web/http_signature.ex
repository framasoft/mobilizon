# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/plugs/http_signature.ex

defmodule MobilizonWeb.HTTPSignaturePlug do
  @moduledoc """
  # HTTPSignaturePlug

  Plug to check HTTP Signatures on every incoming request
  """

  import Plug.Conn
  require Logger

  def init(options) do
    options
  end

  def call(%{assigns: %{valid_signature: true}} = conn, _opts) do
    conn
  end

  def call(conn, _opts) do
    [signature | _] = get_req_header(conn, "signature")

    if signature do
      # set (request-target) header to the appropriate value
      # we also replace the digest header with the one we computed
      conn =
        conn
        |> put_req_header(
          "(request-target)",
          String.downcase("#{conn.method}") <> " #{conn.request_path}"
        )

      conn =
        if conn.assigns[:digest] do
          conn
          |> put_req_header("digest", conn.assigns[:digest])
        else
          conn
        end

      assign(conn, :valid_signature, HTTPSignatures.validate_conn(conn))
    else
      Logger.debug("No signature header!")
      conn
    end
  end
end
