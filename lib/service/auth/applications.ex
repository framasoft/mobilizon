defmodule Mobilizon.Service.Auth.Applications do
  @moduledoc """
  Module to handle applications management
  """
  alias Mobilizon.Applications
  alias Mobilizon.Applications.{Application, ApplicationToken}
  alias Mobilizon.Service.Auth.Authenticator

  @app_access_tokens_ttl {8, :hour}
  @app_refresh_tokens_ttl {26, :week}

  @type access_token_details :: %{
          required(:access_token) => String.t(),
          required(:expires_in) => pos_integer(),
          required(:refresh_token) => String.t(),
          required(:refresh_token_expires_in) => pos_integer(),
          required(:scope) => nil,
          required(:token_type) => String.t()
        }

  def create(name, redirect_uris, scopes, website) do
    client_id = :crypto.strong_rand_bytes(42) |> Base.encode64() |> binary_part(0, 42)
    client_secret = :crypto.strong_rand_bytes(42) |> Base.encode64() |> binary_part(0, 42)

    Applications.create_application(%{
      name: name,
      redirect_uris: redirect_uris,
      scopes: scopes,
      website: website,
      client_id: client_id,
      client_secret: client_secret
    })
  end

  @spec autorize(String.t(), String.t(), String.t(), integer()) ::
          {:ok, String.t()}
          | {:error, :application_not_found}
          | {:error, :redirect_uri_not_in_allowed}
  def autorize(client_id, redirect_uri, _scope, user_id) do
    with %Application{redirect_uris: redirect_uris, id: app_id} <-
           Applications.get_application_by_client_id(client_id),
         {:redirect_uri, true} <-
           {:redirect_uri, redirect_uri in String.split(redirect_uris, "\n")},
         code <- :crypto.strong_rand_bytes(16) |> Base.encode64() |> binary_part(0, 16),
         {:ok, %ApplicationToken{}} <-
           Applications.create_application_token(%{
             user_id: user_id,
             application_id: app_id,
             authorization_code: code
           }) do
      {:ok, code}
    else
      nil ->
        {:error, :application_not_found}

      {:redirect_uri, _} ->
        {:error, :redirect_uri_not_in_allowed}
    end
  end

  @spec generate_access_token(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, access_token_details()}
          | {:error,
             :application_not_found
             | :redirect_uri_not_in_allowed
             | :provided_code_does_not_match
             | :invalid_client_secret
             | :app_token_not_found
             | any()}
  def generate_access_token(client_id, client_secret, code, redirect_uri) do
    with {:application,
          %Application{
            id: application_id,
            client_secret: app_client_secret,
            scopes: scopes,
            redirect_uris: redirect_uris
          }} <-
           {:application, Applications.get_application_by_client_id(client_id)},
         {:redirect_uri, true} <-
           {:redirect_uri, redirect_uri in String.split(redirect_uris, "\n")},
         {:app_token, %ApplicationToken{} = app_token} <-
           {:app_token, Applications.get_application_token_by_authorization_code(code)},
         {:ok, %ApplicationToken{application_id: application_id_from_token} = app_token} <-
           Applications.update_application_token(app_token, %{authorization_code: nil}),
         {:same_app, true} <- {:same_app, application_id === application_id_from_token},
         {:same_client_secret, true} <- {:same_client_secret, app_client_secret == client_secret},
         {:ok, access_token} <-
           Authenticator.generate_access_token(app_token, @app_access_tokens_ttl),
         {:ok, refresh_token} <-
           Authenticator.generate_refresh_token(app_token, @app_refresh_tokens_ttl) do
      {:ok,
       %{
         access_token: access_token,
         expires_in: ttl_to_seconds(@app_access_tokens_ttl),
         refresh_token: refresh_token,
         refresh_token_expires_in: ttl_to_seconds(@app_refresh_tokens_ttl),
         scope: scopes,
         token_type: "bearer"
       }}
    else
      {:application, nil} ->
        {:error, :application_not_found}

      {:same_app, false} ->
        {:error, :provided_code_does_not_match}

      {:same_client_secret, _} ->
        {:error, :invalid_client_secret}

      {:redirect_uri, _} ->
        {:error, :redirect_uri_not_in_allowed}

      {:app_token, _} ->
        {:error, :app_token_not_found}

      {:error, err} ->
        {:error, err}
    end
  end

  def revoke_application_token(%ApplicationToken{} = app_token) do
    Applications.revoke_application_token(app_token)
  end

  @spec ttl_to_seconds({pos_integer(), :second | :minute | :hour | :week}) :: pos_integer()
  defp ttl_to_seconds({value, :second}), do: value
  defp ttl_to_seconds({value, :minute}), do: value * 60
  defp ttl_to_seconds({value, :hour}), do: value * 3600
  defp ttl_to_seconds({value, :week}), do: value * 604_800
end
