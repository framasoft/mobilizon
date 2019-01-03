defmodule MobilizonWeb.Context do
  @moduledoc """
  Guardian context for MobilizonWeb
  """
  @behaviour Plug

  import Plug.Conn
  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn

      user ->
        put_private(conn, :absinthe, %{context: %{current_user: user}})
    end
  end
end
