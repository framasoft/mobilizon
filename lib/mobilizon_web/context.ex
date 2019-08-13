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
    context = %{ip: to_string(:inet_parse.ntoa(conn.remote_ip))}

    context =
      case Guardian.Plug.current_resource(conn) do
        %User{} = user ->
          context
          |> Map.put(:current_user, user)

        nil ->
          context
      end

    put_private(conn, :absinthe, %{context: context})
  end
end
