defmodule MobilizonWeb.Context do
  @moduledoc """
  Guardian context for MobilizonWeb
  """
  @behaviour Plug

  import Plug.Conn
  alias Mobilizon.Users.User

  def init(opts) do
    opts
  end

  def call(conn, _) do
    with %User{} = user <- Guardian.Plug.current_resource(conn) do
      put_private(conn, :absinthe, %{context: %{current_user: user}})
    else
      nil ->
        conn
    end
  end
end
