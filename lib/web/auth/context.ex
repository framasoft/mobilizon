defmodule Mobilizon.Web.Auth.Context do
  @moduledoc """
  Guardian context for Mobilizon.Web
  """
  @behaviour Plug

  import Plug.Conn

  alias Mobilizon.Service.ErrorReporting.Sentry, as: SentryAdapter
  alias Mobilizon.Users.User

  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts) do
    opts
  end

  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(%{assigns: %{ip: _}} = conn, _opts), do: conn

  def call(conn, _opts) do
    set_user_information_in_context(conn)
  end

  @spec set_user_information_in_context(Plug.Conn.t()) :: Plug.Conn.t()
  defp set_user_information_in_context(conn) do
    context = %{ip: conn.remote_ip |> :inet.ntoa() |> to_string()}

    {conn, context} =
      case Guardian.Plug.current_resource(conn) do
        %User{id: user_id, email: user_email} = user ->
          if SentryAdapter.enabled?() do
            Sentry.Context.set_user_context(%{id: user_id, name: user_email})
          end

          context = Map.put(context, :current_user, user)
          conn = assign(conn, :user_locale, user.locale)
          {conn, context}

        nil ->
          {conn, context}
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
