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
        %{"name" => name, "redirect_uri" => redirect_uris, "scope" => scope} = args
      ) do
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()

    case Hammer.check_rate(
           "create_application:#{ip}",
           60_000,
           10
         ) do
      {:allow, _} ->
        case Applications.create(
               name,
               String.split(redirect_uris, "\n"),
               scope,
               Map.get(args, "website")
             ) do
          {:ok, %Application{} = app} ->
            conn
            |> Plug.Conn.put_resp_header("cache-control", "no-store")
            |> json(
              app
              |> Map.take([:name, :website, :client_id, :client_secret, :scope])
              |> Map.put(:redirect_uri, app.redirect_uris)
            )

          {:error, :invalid_scope} ->
            conn
            |> Plug.Conn.put_status(400)
            |> json(%{
              "error" => "invalid_scope",
              "error_description" =>
                dgettext(
                  "errors",
                  "The scope parameter is not a space separated list of valid scopes"
                )
            })

          {:error, error} ->
            Logger.error(inspect(error))

            conn
            |> Plug.Conn.put_status(500)
            |> json(%{
              "error" => "server_error",
              "error_description" =>
                dgettext(
                  "errors",
                  "Impossible to create application."
                )
            })
        end

      {:deny, _} ->
        conn
        |> Plug.Conn.put_status(429)
        |> json(%{
          "error" => "slow_down",
          "error_description" =>
            dgettext(
              "errors",
              "Too many requests"
            )
        })
    end
  end

  def create_application(conn, _args) do
    conn
    |> Plug.Conn.put_status(400)
    |> json(%{
      "error" => "invalid_request",
      "error_description" =>
        dgettext(
          "errors",
          "All of name, scope and redirect_uri parameters are required to create an application"
        )
    })
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

    if is_binary(client_id) and is_binary(redirect_uri) and valid_uri?(redirect_uri) and
         is_binary(state) and is_binary(scope) do
      redirect(conn,
        to:
          ~p"/oauth/autorize_approve?#{[client_id: client_id, redirect_uri: redirect_uri, scope: scope, state: state]}"
      )
    else
      if is_binary(redirect_uri) and valid_uri?(redirect_uri) do
        redirect(conn,
          external:
            append_parameters(redirect_uri,
              error: "invalid_request",
              error_description:
                dgettext(
                  "errors",
                  "You need to specify client_id, redirect_uri, scope and state to autorize an application"
                )
            )
        )
      else
        send_resp(
          conn,
          400,
          dgettext(
            "errors",
            "You need to provide a valid redirect_uri to autorize an application"
          )
        )
      end
    end
  end

  def device_code(conn, %{"client_id" => client_id, "scope" => scope}) do
    case Applications.register_device_code(client_id, scope) do
      {:ok, res} when is_map(res) ->
        conn
        |> Plug.Conn.put_resp_header("cache-control", "no-store")
        |> json(res)

      {:error, :scope_not_included} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{
          "error" => "invalid_scope",
          "error_description" =>
            dgettext(
              "errors",
              "The given scope is not in the list of the app declared scopes"
            )
        })

      {:error, :application_not_found} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{
          "error" => "invalid_client",
          "error_description" =>
            dgettext(
              "errors",
              "No application was found with this client_id"
            )
        })

      {:error, %Ecto.Changeset{} = err} ->
        Logger.error(inspect(err))

        conn
        |> Plug.Conn.put_status(500)
        |> json(%{
          "error" => "server_error",
          "error_description" =>
            dgettext(
              "errors",
              "Unable to produce device code"
            )
        })
    end
  end

  def device_code(conn, _args) do
    conn
    |> Plug.Conn.put_status(400)
    |> json(%{
      "error" => "invalid_request",
      "error_description" =>
        dgettext(
          "errors",
          "You need to pass both client_id and scope as parameters to obtain a device code"
        )
    })
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
        conn
        |> Plug.Conn.put_resp_header("cache-control", "no-store")
        |> json(token)

      {:error, code, msg} ->
        Logger.debug(msg)

        conn
        |> Plug.Conn.put_status(400)
        |> json(%{
          "error" => to_string(code),
          "error_description" => msg
        })
    end
  end

  def generate_access_token(conn, %{
        "client_id" => client_id,
        "device_code" => device_code,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code"
      }) do
    case Applications.generate_access_token_for_device_flow(client_id, device_code) do
      {:ok, res} ->
        conn
        |> Plug.Conn.put_resp_header("cache-control", "no-store")
        |> json(res)

      {:error, :incorrect_device_code} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{
          "error" => "invalid_grant",
          "error_description" =>
            dgettext(
              "errors",
              "The client_id provided or the device_code associated is invalid"
            )
        })

      {:error, :pending, interval} ->
        case Hammer.check_rate(
               "generate_device_access_token:#{client_id}:#{device_code}",
               interval * 1_000,
               1
             ) do
          {:allow, _} ->
            conn
            |> Plug.Conn.put_status(400)
            |> json(%{
              "error" => "authorization_pending",
              "error_description" =>
                dgettext(
                  "errors",
                  "The authorization request is still pending"
                )
            })

          {:deny, _} ->
            conn
            |> Plug.Conn.put_status(400)
            |> json(%{
              "error" => "slow_down",
              "error_description" =>
                dgettext(
                  "errors",
                  "Please slow down the rate of your requests"
                )
            })
        end

      {:error, :access_denied} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{
          "error" => "access_denied",
          "error_description" =>
            dgettext(
              "errors",
              "The user rejected the requested authorization"
            )
        })

      {:error, :expired} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{
          "error" => "expired_token",
          "error_description" =>
            dgettext(
              "errors",
              "The given device_code has expired"
            )
        })
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
        conn
        |> Plug.Conn.put_resp_header("cache-control", "no-store")
        |> json(res)

      {:error, :invalid_client_credentials} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{
          "error" => "invalid_client",
          "error_description" => dgettext("errors", "Invalid client credentials provided")
        })

      {:error, :invalid_refresh_token} ->
        conn
        |> Plug.Conn.put_status(400)
        |> json(%{
          "error" => "invalid_grant",
          "error_description" => dgettext("errors", "Invalid refresh token provided")
        })

      {:error, err} when is_atom(err) ->
        conn
        |> Plug.Conn.put_status(500)
        |> json(%{
          "error" => "server_error",
          "error_description" => to_string(err)
        })
    end
  end

  def generate_access_token(conn, _args) do
    conn
    |> Plug.Conn.put_status(400)
    |> json(%{
      "error" => "invalid_request",
      "error_description" =>
        dgettext(
          "errors",
          "Incorrect parameters sent. You need to provide at least the grant_type and client_id parameters, depending on the grant type being used."
        )
    })
  end

  def revoke_token(conn, %{"token" => token} = _args) do
    case Applications.revoke_token(token) do
      {:ok, _res} ->
        send_resp(conn, 200, "")

      {:error, _, _, _} ->
        conn
        |> Plug.Conn.put_status(500)
        |> json(%{
          "error" => "server_error",
          "error_description" => dgettext("errors", "Unable to revoke token")
        })

      {:error, :token_not_found} ->
        conn
        |> Plug.Conn.put_status(:not_found)
        |> json(%{
          "error" => "invalid_request",
          "error_description" => dgettext("errors", "Token not found")
        })
    end
  end

  @spec do_generate_access_token(String.t(), String.t(), String.t(), String.t(), String.t()) ::
          {:ok, Applications.access_token_details()} | {:error, atom(), String.t()}
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
        {:error, :invalid_request,
         dgettext("errors", "No application was found with this client_id")}

      {:error, :redirect_uri_not_in_allowed} ->
        {:error, :invalid_request, dgettext("errors", "This redirect URI is not allowed")}

      {:error, :invalid_or_expired} ->
        {:error, :invalid_grant, dgettext("errors", "The provided code is invalid or expired")}

      {:error, :provided_code_does_not_match} ->
        {:error, :invalid_grant,
         dgettext("errors", "The provided client_id does not match the provided code")}

      {:error, :invalid_client_secret} ->
        {:error, :invalid_client, dgettext("errors", "The provided client_secret is invalid")}

      {:error, :scope_not_included} ->
        {:error, :invalid_scope,
         dgettext(
           "errors",
           "The provided scope is invalid or not included in the app declared scopes"
         )}
    end
  end

  defp valid_uri?(url) do
    uri = URI.parse(url)
    uri.scheme != nil and (uri.host =~ "." or uri.host == "localhost")
  end

  @spec append_parameters(String.t(), Enum.t()) :: String.t()
  defp append_parameters(uri_str, parameters) do
    query_parameters = URI.encode_query(parameters)

    case URI.parse(uri_str) do
      %URI{query: nil} = uri ->
        uri
        |> URI.merge(%URI{query: query_parameters})
        |> URI.to_string()

      uri ->
        "#{URI.to_string(uri)}&#{query_parameters}"
    end
  end
end
