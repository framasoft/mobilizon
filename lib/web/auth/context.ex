defmodule Mobilizon.Web.Auth.Context do
  @moduledoc """
  Guardian context for Mobilizon.Web
  """
  @behaviour Plug

  import Plug.Conn

  alias Mobilizon.Users.User

  def init(opts) do
    opts
  end

  def call(%{assigns: %{ip: _}} = conn, _opts), do: conn

  def call(conn, _opts) do
    set_user_information_in_context(conn)
  end

  def set_user_information_in_context(conn) do
    context = %{ip: conn.remote_ip |> :inet.ntoa() |> to_string()}

    context =
      case Guardian.Plug.current_resource(conn) do
        %User{id: user_id, email: user_email} = user ->
          Sentry.Context.set_user_context(%{id: user_id, name: user_email})
          Map.put(context, :current_user, user)

        nil ->
          context
      end

    context =
      case get_req_header(conn, "user-agent") do
        [user_agent | _] ->
          Map.put(context, :user_agent, user_agent)

        _ ->
          context
      end

    put_private(conn, :absinthe, %{context: context})
  end
end
