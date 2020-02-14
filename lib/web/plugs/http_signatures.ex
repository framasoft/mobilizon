# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/plugs/http_signature.ex

defmodule Mobilizon.Web.Plugs.HTTPSignatures do
  @moduledoc """
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
    case get_req_header(conn, "signature") do
      [signature | _] ->
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

          signature_valid = HTTPSignatures.validate_conn(conn)
          Logger.debug("Is signature valid ? #{inspect(signature_valid)}")
          date_valid = date_valid?(conn)
          assign(conn, :valid_signature, signature_valid && date_valid)
        else
          Logger.debug("No signature header!")
          conn
        end

      _ ->
        conn
    end
  end

  @spec date_valid?(Plug.Conn.t()) :: boolean()
  defp date_valid?(conn) do
    with [date | _] <- get_req_header(conn, "date") || [""],
         {:ok, date} <- Timex.parse(date, "{WDshort}, {0D} {Mshort} {YYYY} {h24}:{m}:{s} GMT") do
      Timex.diff(date, DateTime.utc_now(), :hours) <= 12 &&
        Timex.diff(date, DateTime.utc_now(), :hours) >= -12
    else
      _ -> false
    end
  end
end
