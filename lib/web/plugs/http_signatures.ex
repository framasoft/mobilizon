# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/plugs/http_signature.ex

defmodule Mobilizon.Web.Plugs.HTTPSignatures do
  @moduledoc """
  Plug to check HTTP Signatures on every incoming request
  """

  import Plug.Conn, only: [get_req_header: 2, put_req_header: 3, assign: 3]

  require Logger

  def init(options) do
    options
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(%{assigns: %{valid_signature: true}} = conn, _opts) do
    conn
  end

  def call(conn, _opts) do
    signature = conn |> get_req_header("signature") |> List.first()

    if is_nil(signature) do
      Logger.debug("No signature header!")
      conn
    else
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
    end
  end

  @spec date_valid?(Plug.Conn.t()) :: boolean()
  defp date_valid?(conn) do
    date = conn |> get_req_header("date") |> List.first()

    if is_nil(date) do
      false
    else
      case Timex.parse(date, "{WDshort}, {0D} {Mshort} {YYYY} {h24}:{m}:{s} GMT") do
        {:ok, %NaiveDateTime{} = date} ->
          date
          |> DateTime.from_naive!("Etc/UTC")
          |> date_diff_ok?()

        {:ok, %DateTime{} = date} ->
          date_diff_ok?(date)

        {:error, _err} ->
          false
      end
    end
  end

  @spec date_diff_ok?(DateTime.t()) :: boolean()
  defp date_diff_ok?(%DateTime{} = date) do
    DateTime.diff(date, DateTime.utc_now()) <= 12 * 3600 &&
      DateTime.diff(date, DateTime.utc_now()) >= -12 * 3600
  end
end
