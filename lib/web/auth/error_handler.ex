defmodule Mobilizon.Web.Auth.ErrorHandler do
  @moduledoc """
  In case we have an auth error
  """
  import Plug.Conn

  # sobelow_skip ["XSS.SendResp"]
  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{message: to_string(type)})
    send_resp(conn, 401, body)
  end
end
