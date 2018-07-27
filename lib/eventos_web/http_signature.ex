defmodule EventosWeb.HTTPSignaturePlug do
  @moduledoc """
  # HTTPSignaturePlug

  Plug to check HTTP Signatures on every incoming request
  """

  alias Eventos.Service.HTTPSignatures
  import Plug.Conn
  require Logger

  def init(options) do
    options
  end

  def call(%{assigns: %{valid_signature: true}} = conn, _opts) do
    conn
  end

  def call(conn, _opts) do
    user = conn.params["actor"]

    Logger.debug(fn ->
      "Checking sig for #{user}"
    end)

    with [signature | _] <- get_req_header(conn, "signature") do
      cond do
        signature && String.contains?(signature, user) ->
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
    else
      _ ->
        Logger.debug("No signature header!")
        conn
    end
  end
end
