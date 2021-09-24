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

    user_agent = conn |> Plug.Conn.get_req_header("user-agent") |> List.first()

    {conn, context} =
      case Guardian.Plug.current_resource(conn) do
        %User{id: user_id, email: user_email} = user ->
          if SentryAdapter.enabled?() do
            Sentry.Context.set_user_context(%{id: user_id, name: user_email})

            Sentry.Context.set_request_context(%{
              url: Plug.Conn.request_url(conn),
              method: conn.method,
              headers: %{
                "User-Agent": user_agent
              },
              query_string: conn.query_string,
              env: %{
                REQUEST_ID: conn |> Plug.Conn.get_resp_header("x-request-id") |> List.first(),
                SERVER_NAME: conn.host
              }
            })
          end

          context = Map.put(context, :current_user, user)
          conn = assign(conn, :user_locale, user.locale)
          {conn, context}

        nil ->
          {conn, context}
      end

    context = if is_nil(user_agent), do: context, else: Map.put(context, :user_agent, user_agent)

    put_private(conn, :absinthe, %{context: context})
  end
end
