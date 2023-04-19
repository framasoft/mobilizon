defmodule Mobilizon.Service.Auth.Applications do
  @moduledoc """
  Module to handle applications management
  """
  alias Mobilizon.Applications
  alias Mobilizon.Applications.{Application, ApplicationDeviceActivation, ApplicationToken}
  alias Mobilizon.GraphQL.Authorization.AppScope
  alias Mobilizon.Service.Auth.Authenticator
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Auth.Guardian
  alias Mobilizon.Web.Router.Helpers, as: Routes
  require Logger

  @app_access_tokens_ttl {8, :hour}
  @app_refresh_tokens_ttl {26, :week}

  @device_code_expires_in 900
  @device_code_interval 5

  @authorization_code_lifetime 60
  @application_device_activation_lifetime @device_code_expires_in * 2

  @type access_token_details :: %{
          required(:access_token) => String.t(),
          required(:expires_in) => pos_integer(),
          required(:refresh_token) => String.t(),
          required(:refresh_token_expires_in) => pos_integer(),
          required(:scope) => nil,
          required(:token_type) => String.t()
        }

  @spec create(String.t(), list(String.t()), String.t(), String.t() | nil) ::
          {:ok, Application.t()} | {:error, Ecto.Changeset.t()} | {:error, :invalid_scope}
  def create(name, redirect_uris, scope, website \\ nil) do
    if AppScope.scopes_valid?(scope) do
      client_id = :crypto.strong_rand_bytes(42) |> Base.encode64() |> binary_part(0, 42)
      client_secret = :crypto.strong_rand_bytes(42) |> Base.encode64() |> binary_part(0, 42)

      Applications.create_application(%{
        name: name,
        redirect_uris: redirect_uris,
        scope: scope,
        website: website,
        client_id: client_id,
        client_secret: client_secret
      })
    else
      {:error, :invalid_scope}
    end
  end

  @spec autorize(String.t(), String.t(), String.t(), integer()) ::
          {:ok, ApplicationToken.t()}
          | {:error, :application_not_found}
          | {:error, :redirect_uri_not_in_allowed}
          | {:error, Ecto.Changeset.t()}
  def autorize(client_id, redirect_uri, scope, user_id) do
    with %Application{redirect_uris: redirect_uris, id: app_id} <-
           Applications.get_application_by_client_id(client_id),
         {:redirect_uri, true} <-
           {:redirect_uri, redirect_uri in redirect_uris},
         code <- :crypto.strong_rand_bytes(16) |> Base.encode64() |> binary_part(0, 16) do
      Applications.create_application_token(%{
        user_id: user_id,
        application_id: app_id,
        authorization_code: code,
        scope: scope,
        status: :pending
      })
    else
      nil ->
        {:error, :application_not_found}

      {:redirect_uri, _} ->
        {:error, :redirect_uri_not_in_allowed}
    end
  end

  @spec autorize_device_application(String.t(), String.t()) ::
          {:ok, ApplicationDeviceActivation.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :expired}
          | {:error, :access_denied}
          | {:error, :not_found}
  def autorize_device_application(client_id, user_code) do
    Logger.debug(
      "Authorizing device application client_id: #{client_id}, user_code: #{user_code}"
    )

    case Applications.get_application_device_activation_by_user_code(user_code) do
      %ApplicationDeviceActivation{
        status: :confirmed,
        application: %Application{client_id: ^client_id}
      } = app_device_activation ->
        if device_activation_expired?(app_device_activation) do
          {:error, :expired}
        else
          Applications.update_application_device_activation(app_device_activation, %{
            status: :success
          })
        end

      # The device activation is confirmed, but does not match the given app client_id, so we say it's not found
      %ApplicationDeviceActivation{status: :confirmed} ->
        {:error, :not_found}

      %ApplicationDeviceActivation{} ->
        {:error, :not_confirmed}

      nil ->
        {:error, :not_found}
    end
  end

  @spec generate_access_token(String.t(), String.t(), String.t(), String.t(), String.t()) ::
          {:ok, access_token_details()}
          | {:error,
             :application_not_found
             | :redirect_uri_not_in_allowed
             | :provided_code_does_not_match
             | :invalid_client_secret
             | :invalid_or_expired
             | :scope_not_included
             | any()}
  def generate_access_token(client_id, client_secret, code, redirect_uri, scope) do
    with {:application,
          %Application{
            id: application_id,
            client_secret: app_client_secret,
            redirect_uris: redirect_uris,
            scope: app_scope
          }} <-
           {:application, Applications.get_application_by_client_id(client_id)},
         {:scope_included, true} <- {:scope_included, request_scope_valid?(app_scope, scope)},
         {:redirect_uri, true} <-
           {:redirect_uri, redirect_uri in redirect_uris},
         {:app_token, %ApplicationToken{} = app_token} <-
           {:app_token, Applications.get_application_token_by_authorization_code(code)},
         {:expired, false} <- {:expired, authorization_code_expired?(app_token)},
         {:ok, %ApplicationToken{application_id: application_id_from_token} = app_token} <-
           Applications.update_application_token(app_token, %{
             authorization_code: nil,
             status: :success
           }),
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
         scope: scope,
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
        {:error, :invalid_or_expired}

      {:expired, true} ->
        {:error, :invalid_or_expired}

      {:scope_included, false} ->
        {:error, :scope_not_included}

      {:error, err} ->
        {:error, err}
    end
  end

  def generate_access_token_for_device_flow(client_id, device_code) do
    Logger.debug(
      "Generating access token for application device with client_id=#{client_id}, device_code=#{device_code}"
    )

    case Applications.get_application_device_activation_by_device_code(client_id, device_code) do
      %ApplicationDeviceActivation{status: :success, scope: scope, user_id: user_id} =
          app_device_activation ->
        if device_activation_expired?(app_device_activation) do
          {:error, :expired}
        else
          %Application{id: app_id} = Applications.get_application_by_client_id(client_id)

          {:ok, %ApplicationToken{} = app_token} =
            Applications.create_application_token(%{
              user_id: user_id,
              application_id: app_id,
              authorization_code: nil,
              scope: scope,
              status: :success
            })

          {:ok, access_token} =
            Authenticator.generate_access_token(app_token, @app_access_tokens_ttl)

          {:ok, refresh_token} =
            Authenticator.generate_refresh_token(app_token, @app_refresh_tokens_ttl)

          {:ok,
           %{
             access_token: access_token,
             expires_in: ttl_to_seconds(@app_access_tokens_ttl),
             refresh_token: refresh_token,
             refresh_token_expires_in: ttl_to_seconds(@app_refresh_tokens_ttl),
             scope: scope,
             token_type: "bearer"
           }}
        end

      %ApplicationDeviceActivation{status: :incorrect_device_code} ->
        {:error, :incorrect_device_code}

      %ApplicationDeviceActivation{status: :access_denied} ->
        {:error, :access_denied}

      %ApplicationDeviceActivation{status: :pending} ->
        {:error, :pending, @device_code_interval}

      nil ->
        {:error, :incorrect_device_code}

      err ->
        Logger.error(inspect(err))
        {:error, :incorrect_device_code}
    end
  end

  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("", trim: true)

  defp string_of_length(length) do
    1..length
    |> Enum.reduce([], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end

  @spec register_device_code(String.t(), String.t() | nil) ::
          {:ok, ApplicationDeviceActivation.t()}
          | {:error, :application_not_found}
          | {:error, :scope_not_included}
          | {:error, Ecto.Changeset.t()}
  def register_device_code(client_id, scope) do
    with {:app, %Application{scope: app_scope} = application} <-
           {:app, Applications.get_application_by_client_id(client_id)},
         {device_code, user_code, verification_uri} <-
           {string_of_length(40), string_of_length(8),
            Routes.page_url(Mobilizon.Web.Endpoint, :auth_device)},
         {:scope_included, true} <- {:scope_included, request_scope_valid?(app_scope, scope)},
         {:ok, %ApplicationDeviceActivation{} = application_device_activation} <-
           Applications.create_application_device_activation(%{
             device_code: device_code,
             user_code: user_code,
             expires_in: @device_code_expires_in,
             application_id: application.id,
             scope: scope
           }) do
      {:ok,
       application_device_activation
       |> Map.from_struct()
       |> Map.take([:device_code, :user_code, :expires_in])
       |> Map.update!(:user_code, &user_code_displayed/1)
       |> Map.merge(%{
         interval: @device_code_interval,
         verification_uri: verification_uri
       })}
    else
      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}

      {:app, nil} ->
        {:error, :application_not_found}

      {:scope_included, false} ->
        {:error, :scope_not_included}
    end
  end

  @spec activate_device(String.t(), User.t()) ::
          {:ok, ApplicationDeviceActivation.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :not_found}
          | {:error, :expired}
  def activate_device(user_code, user) do
    case Applications.get_application_device_activation_by_user_code(user_code) do
      %ApplicationDeviceActivation{} = app_device_activation ->
        if device_activation_expired?(app_device_activation) do
          {:error, :expired}
        else
          Applications.update_application_device_activation(app_device_activation, %{
            status: :confirmed,
            user_id: user.id
          })
        end

      _ ->
        {:error, :not_found}
    end
  end

  @spec refresh_tokens(String.t(), String.t(), String.t()) ::
          {:ok, access_token_details()}
          | {:error, :invalid_client_credentials}
          | {:error, :invalid_refresh_token}
          | {:error, any()}
  def refresh_tokens(refresh_token, user_client_id, user_client_secret) do
    with {:resource_from_token,
          {:ok,
           %ApplicationToken{
             application: %Application{client_id: app_client_id, client_secret: app_client_secret},
             scope: scope
           } = app_token,
           _claims}} <- {:resource_from_token, Guardian.resource_from_token(refresh_token)},
         {:valid_client_credentials, true} <-
           {:valid_client_credentials,
            app_client_id == user_client_id and app_client_secret == user_client_secret},
         {:ok, _old, {exchanged_token, _claims}} <-
           Guardian.exchange(refresh_token, "refresh", "access", ttl: @app_access_tokens_ttl),
         {:ok, new_refresh_token} <-
           Authenticator.generate_refresh_token(app_token, @app_refresh_tokens_ttl),
         {:ok, _claims} <- Guardian.revoke(refresh_token) do
      {:ok,
       %{
         access_token: exchanged_token,
         expires_in: ttl_to_seconds(@app_access_tokens_ttl),
         refresh_token: new_refresh_token,
         refresh_token_expires_in: ttl_to_seconds(@app_refresh_tokens_ttl),
         scope: scope,
         token_type: "bearer"
       }}
    else
      {:valid_client_credentials, false} ->
        {:error, :invalid_client_credentials}

      {:resource_from_token, _} ->
        {:error, :invalid_refresh_token}
    end
  end

  defp user_code_displayed(user_code) do
    String.slice(user_code, 0..3) <> "-" <> String.slice(user_code, 4..7)
  end

  def revoke_application_token(%ApplicationToken{} = app_token) do
    Applications.revoke_application_token(app_token)
  end

  @spec ttl_to_seconds({pos_integer(), :second | :minute | :hour | :week}) :: pos_integer()
  defp ttl_to_seconds({value, :second}), do: value
  defp ttl_to_seconds({value, :minute}), do: value * 60
  defp ttl_to_seconds({value, :hour}), do: value * 3600
  defp ttl_to_seconds({value, :week}), do: value * 604_800

  @spec device_activation_expired?(ApplicationDeviceActivation.t()) :: boolean()
  defp device_activation_expired?(%ApplicationDeviceActivation{
         inserted_at: inserted_at,
         expires_in: expires_in
       }) do
    NaiveDateTime.compare(NaiveDateTime.add(inserted_at, expires_in), NaiveDateTime.utc_now()) ==
      :lt
  end

  def prune_old_tokens do
    Applications.prune_old_application_tokens(@authorization_code_lifetime)
  end

  def prune_old_application_device_activations do
    Applications.prune_old_application_device_activations(@application_device_activation_lifetime)
  end

  @spec revoke_token(String.t()) ::
          {:ok, map()}
          | {:error, any(), any(), any()}
          | {:error, :token_not_found}
  def revoke_token(token) do
    case Guardian.resource_from_token(token) do
      {:ok, %ApplicationToken{} = app_token, _claims} ->
        Guardian.revoke(token)
        revoke_application_token(app_token)

      {:error, _err} ->
        {:error, :token_not_found}
    end
  end

  defp authorization_code_expired?(%ApplicationToken{inserted_at: inserted_at}) do
    NaiveDateTime.compare(NaiveDateTime.add(inserted_at, 60), NaiveDateTime.utc_now()) ==
      :lt
  end

  defp request_scope_valid?(app_scope, request_scope) do
    app_scopes = app_scope |> String.split(" ") |> MapSet.new()
    request_scopes = request_scope |> String.split(" ") |> MapSet.new()
    MapSet.subset?(request_scopes, app_scopes) and AppScope.scopes_valid?(request_scope)
  end
end
