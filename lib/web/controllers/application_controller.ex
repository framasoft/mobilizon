defmodule Mobilizon.Web.ApplicationController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Applications.{Application, ApplicationDeviceActivation}
  alias Mobilizon.Service.Auth.Applications
  plug(:put_layout, false)
  import Mobilizon.Web.Gettext, only: [dgettext: 2]
  require Logger

  @doc """
  Create an application
  """
  @spec create_application(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create_application(conn, %{"name" => name, "redirect_uris" => redirect_uris} = args) do
    case Applications.create(
           name,
           redirect_uris,
           Map.get(args, "scopes"),
           Map.get(args, "website")
         ) do
      {:ok, %Application{} = app} ->
        json(
          conn,
          Map.take(app, [:name, :website, :redirect_uris, :client_id, :client_secret, :scope])
        )

      {:error, _error} ->
        send_resp(
          conn,
          500,
          dgettext(
            "errors",
            "Impossible to create application."
          )
        )
    end
  end

  def create_application(conn, _args) do
    send_resp(
      conn,
      400,
      dgettext(
        "errors",
        "Both name and redirect_uri parameters are required to create an application"
      )
    )
  end

  @doc """
  Authorize
  """
  @spec authorize(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorize(
        conn,
        _args
      ) do
    conn = fetch_query_params(conn)

    client_id = conn.query_params["client_id"]
    redirect_uri = conn.query_params["redirect_uri"]
    state = conn.query_params["state"]

    if is_binary(client_id) and is_binary(redirect_uri) and is_binary(state) do
      redirect(conn,
        to:
          Routes.page_path(conn, :authorize,
            client_id: client_id,
            redirect_uri: redirect_uri,
            scope: conn.query_params["scope"],
            state: state
          )
      )
    else
      send_resp(
        conn,
        400,
        dgettext(
          "errors",
          "You need to specify client_id, redirect_uri and state to autorize an application"
        )
      )
    end
  end

  def device_code(conn, %{"client_id" => client_id} = args) do
    case Applications.register_device_code(client_id, Map.get(args, "scope")) do
      {:ok, res} when is_map(res) ->
        case get_format(conn) do
          "json" ->
            json(conn, res)

          _ ->
            send_resp(conn, 200, URI.encode_query(res))
        end

      {:error, %Ecto.Changeset{} = err} ->
        Logger.error(inspect(err))
        send_resp(conn, 500, "Unable to produce device code")
    end
  end

  def device_code(conn, _args) do
    send_resp(conn, 400, "You need to send to send at least client_id to obtain a device code")
  end

  @spec generate_access_token(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def generate_access_token(conn, %{
        "client_id" => client_id,
        "client_secret" => client_secret,
        "code" => code,
        "redirect_uri" => redirect_uri
      }) do
    case Applications.generate_access_token(client_id, client_secret, code, redirect_uri) do
      {:ok, token} ->
        redirect(conn, external: generate_redirect_with_query_params(redirect_uri, token))

      {:error, :application_not_found} ->
        send_resp(conn, 400, dgettext("errors", "No application was found with this client_id"))

      {:error, :redirect_uri_not_in_allowed} ->
        send_resp(conn, 400, dgettext("errors", "This redirect URI is not allowed"))

      {:error, :invalid_or_expired} ->
        send_resp(conn, 400, dgettext("errors", "The provided code is invalid or expired"))

      {:error, :invalid_client_id} ->
        send_resp(
          conn,
          400,
          dgettext("errors", "The provided client_id does not match the provided code")
        )

      {:error, :invalid_client_secret} ->
        send_resp(conn, 400, dgettext("errors", "The provided client_secret is invalid"))

      {:error, :user_not_found} ->
        send_resp(conn, 400, dgettext("errors", "The user for this code was not found"))
    end
  end

  def generate_access_token(conn, %{
        "client_id" => client_id,
        "device_code" => device_code,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "_format" => "json"
      }) do
    json(conn, Applications.generate_access_token(client_id, device_code))
  end

  def generate_access_token(conn, %{
        "client_id" => client_id,
        "device_code" => device_code,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code"
      }) do
    send_resp(
      conn,
      200,
      URI.encode_query(Applications.generate_access_token(client_id, device_code))
    )
  end

  @spec generate_redirect_with_query_params(String.t(), map()) :: String.t()
  defp generate_redirect_with_query_params(redirect_uri, query_params) do
    redirect_uri |> URI.parse() |> URI.merge("?" <> URI.encode_query(query_params)) |> to_string()
  end
end
