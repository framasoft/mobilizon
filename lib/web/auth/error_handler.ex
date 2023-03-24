defmodule Mobilizon.Web.Auth.ErrorHandler do
  @moduledoc """
  In case we have an auth error
  """
  import Plug.Conn
  require Logger

  # sobelow_skip ["XSS.SendResp"]
  @spec auth_error(Plug.Conn.t(), any(), any()) :: Plug.Conn.t()
  def auth_error(conn, {type, reason}, _opts) do
    body = Jason.encode!(%{message: to_string(type), details: inspect(reason)})
    send_resp(conn, 401, body)
  end
end
