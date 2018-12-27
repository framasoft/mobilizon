# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/plugs/http_signature.ex

defmodule MobilizonWeb.HTTPSignaturePlug do
  @moduledoc """
  # HTTPSignaturePlug

  Plug to check HTTP Signatures on every incoming request
  """

  alias Mobilizon.Service.HTTPSignatures
  import Plug.Conn
  require Logger

  def init(options) do
    options
  end

  def call(%{assigns: %{valid_signature: true}} = conn, _opts) do
    conn
  end

  def call(conn, _opts) do
    actor = conn.params["actor"]

    Logger.debug(fn ->
      "Checking sig for #{actor}"
    end)

    [signature | _] = get_req_header(conn, "signature")

    cond do
      # Dialyzer doesn't like this line
      signature && String.contains?(signature, actor) ->
        conn =
          conn
          |> put_req_header(
            "(request-target)",
            String.downcase("#{conn.method}") <> " #{conn.request_path}"
          )

        assign(conn, :valid_signature, HTTPSignatures.validate_conn(conn))

      signature ->
        Logger.debug("Signature not from actor")
        assign(conn, :valid_signature, false)

      true ->
        Logger.debug("No signature header!")
        conn
    end
  end
end
