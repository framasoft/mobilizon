defmodule Mobilizon.Web.RequestContext do
  @moduledoc """
  Module to put some context into the request
  """

  @spec put_request_context(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def put_request_context(%Plug.Conn{} = conn, _opts \\ []) do
    if Application.get_env(:sentry, :dsn) != nil do
      Sentry.Context.set_request_context(%{
        url: Plug.Conn.request_url(conn),
        method: conn.method,
        headers: %{
          "User-Agent": conn |> Plug.Conn.get_req_header("user-agent") |> List.first(),
          Referer: conn |> Plug.Conn.get_req_header("referer") |> List.first(),
          "Accept-Language": conn |> Plug.Conn.get_req_header("accept-language") |> List.first()
        },
        query_string: conn.query_string,
        env: %{
          REQUEST_ID: conn |> Plug.Conn.get_resp_header("x-request-id") |> List.first(),
          SERVER_NAME: conn.host
        }
      })
    end

    conn
  end
end
