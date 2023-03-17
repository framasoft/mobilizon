defmodule Mobilizon.Web.ApplicationController do
  use Mobilizon.Web, :controller

  alias Mobilizon.Applications.Application
  alias Mobilizon.Service.Auth.Applications
  plug(:put_layout, false)
  import Mobilizon.Web.Gettext, only: [dgettext: 2]
  require Logger

  @doc """
  Create an application
  """
  @spec create_application(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create_application(
        conn,
        %{"name" => name, "redirect_uris" => redirect_uris, "scope" => scope} = args
      ) do
    case Applications.create(
           name,
           String.split(redirect_uris, "\n"),
           scope,
           Map.get(args, "website")
         ) do
      {:ok, %Application{} = app} ->
        json(
          conn,
          Map.take(app, [:name, :website, :redirect_uris, :client_id, :client_secret, :scope])
        )

      {:error, :invalid_scope} ->
        send_resp(
          conn,
          400,
          dgettext(
            "errors",
            "The scope parameter is not a space separated list of valid scopes"
          )
        )

      {:error, error} ->
        Logger.error(inspect(error))

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
        "All of name, scope and redirect_uri parameters are required to create an application"
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
    scope = conn.query_params["scope"]

    if is_binary(client_id) and is_binary(redirect_uri) and is_binary(state) and is_binary(scope) do
      redirect(conn,
        to:
          Routes.page_path(conn, :authorize,
            client_id: client_id,
            redirect_uri: redirect_uri,
            scope: scope,
            state: state
          )
      )
    else
      send_resp(
        conn,
        400,
        dgettext(
          "errors",
          "You need to specify client_id, redirect_uri, scope and state to autorize an application"
        )
      )
    end
  end

  def device_code(conn, %{"client_id" => client_id, "scope" => scope}) do
    case Applications.register_device_code(client_id, scope) do
      {:ok, res} when is_map(res) ->
        case get_format(conn) do
          "json" ->
            json(conn, res)

          _ ->
            send_resp(conn, 200, URI.encode_query(res))
        end

      {:error, :scope_not_included} ->
        send_resp(conn, 400, "The given scope is not in the list of the app declared scopes")

      {:error, :application_not_found} ->
        send_resp(conn, 400, "No application with this client_id was found")

      {:error, %Ecto.Changeset{} = err} ->
        Logger.error(inspect(err))
        send_resp(conn, 500, "Unable to produce device code")
    end
  end

  def device_code(conn, _args) do
    send_resp(
      conn,
      400,
      "You need to pass both client_id and scope as parameters to obtain a device code"
    )
  end

  @spec generate_access_token(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def generate_access_token(conn, %{
        "client_id" => client_id,
        "client_secret" => client_secret,
        "code" => code,
        "redirect_uri" => redirect_uri,
        "scope" => scope,
        "grant_type" => "authorization_code"
      }) do
    case do_generate_access_token(client_id, client_secret, code, redirect_uri, scope) do
      {:ok, token} ->
        json(conn, token)

      {:error, msg} ->
        Logger.debug(msg)
        json(conn, %{error: true, details: msg})
    end
  end

  def generate_access_token(conn, %{
        "client_id" => client_id,
        "device_code" => device_code,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code"
      }) do
    case Applications.generate_access_token_for_device_flow(client_id, device_code) do
      {:ok, res} ->
        case get_format(conn) do
          "json" ->
            json(conn, res)

          _ ->
            send_resp(
              conn,
              200,
              URI.encode_query(res)
            )
        end

      {:error, :incorrect_device_code} ->
        send_resp(conn, 400, "The client_id provided or the device_code associated is invalid")

      {:error, :access_denied} ->
        send_resp(conn, 401, "The user rejected the requested authorization")

      {:error, :expired} ->
        send_resp(conn, 400, "The given device_code has expired")
    end
  end

  def generate_access_token(conn, %{
        "refresh_token" => refresh_token,
        "grant_type" => "refresh_token",
        "client_id" => client_id,
        "client_secret" => client_secret
      }) do
    case Applications.refresh_tokens(refresh_token, client_id, client_secret) do
      {:ok, res} ->
        json(conn, res)

      {:error, :invalid_client_credentials} ->
        send_resp(conn, 400, "Invalid client credentials provided")

      {:error, :invalid_refresh_token} ->
        send_resp(conn, 400, "Invalid refresh token provided")

      {:error, err} when is_atom(err) ->
        send_resp(conn, 500, to_string(err))
    end
  end

  def generate_access_token(conn, _args) do
    send_resp(
      conn,
      400,
      "Incorrect parameters sent. You need to provide at least the grant_type and client_id parameters, depending on the grant type being used."
    )
  end

  @spec do_generate_access_token(String.t(), String.t(), String.t(), String.t(), String.t()) ::
          {:ok, Applications.access_token_details()} | {:error, String.t()}
  defp do_generate_access_token(client_id, client_secret, code, redirect_uri, scope) do
    case Applications.generate_access_token(
           client_id,
           client_secret,
           code,
           redirect_uri,
           scope
         ) do
      {:ok, token} ->
        {:ok, token}

      {:error, :application_not_found} ->
        {:error, dgettext("errors", "No application was found with this client_id")}

      {:error, :redirect_uri_not_in_allowed} ->
        {:error, dgettext("errors", "This redirect URI is not allowed")}

      {:error, :invalid_or_expired} ->
        {:error, dgettext("errors", "The provided code is invalid or expired")}

      {:error, :provided_code_does_not_match} ->
        {:error, dgettext("errors", "The provided client_id does not match the provided code")}

      {:error, :invalid_client_secret} ->
        {:error, dgettext("errors", "The provided client_secret is invalid")}
    end
  end
end
