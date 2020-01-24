defmodule MobilizonWeb.Auth.ErrorHandler do
  @moduledoc """
  In case we have an auth error
  """
  import Plug.Conn

  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{message: to_string(type)})
    send_resp(conn, 401, body)
  end
end
