defmodule Mobilizon.GraphQL.Resolvers.Application do
  @moduledoc """
  Handles the Application-related GraphQL calls.
  """

  alias Mobilizon.Applications, as: ApplicationManager
  alias Mobilizon.Applications.{Application, ApplicationDeviceActivation, ApplicationToken}
  alias Mobilizon.GraphQL.Error
  alias Mobilizon.Service.Auth.Applications
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext, only: [dgettext: 2]

  require Logger

  @doc """
  Authorize an application
  """
  @spec authorize(any(), map(), Absinthe.Resolution.t()) :: {:ok, map()} | {:error, String.t()}
  def authorize(
        _parent,
        %{client_id: client_id, redirect_uri: redirect_uri, scope: scope} = args,
        %{context: %{current_user: %User{id: user_id}}}
      ) do
    case Applications.autorize(client_id, redirect_uri, scope, user_id) do
      {:ok,
       %ApplicationToken{
         application: %Application{client_id: client_id},
         scope: scope,
         authorization_code: code
       }} ->
        {:ok, %{code: code, state: Map.get(args, :state), client_id: client_id, scope: scope}}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}

      {:error, :application_not_found} ->
        {:error,
         dgettext(
           "errors",
           "No application with this client_id was found"
         )}

      {:error, :redirect_uri_not_in_allowed} ->
        {:error,
         dgettext(
           "errors",
           "The given redirect_uri is not in the list of allowed redirect URIs"
         )}
    end
  end

  def authorize(_parent, _args, _context) do
    {:error, :unauthenticated}
  end

  @spec get_application(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Application.t()} | {:error, :application_not_found | :unauthenticated}
  def get_application(_parent, %{client_id: client_id}, %{context: %{current_user: %User{}}}) do
    case ApplicationManager.get_application_by_client_id(client_id) do
      %Application{} = application ->
        {:ok, application}

      nil ->
        {:error, :application_not_found}
    end
  end

  def get_application(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  def get_user_applications(_parent, _args, %{context: %{current_user: %User{id: user_id}}}) do
    {:ok, ApplicationManager.list_application_tokens_for_user_id(user_id)}
  end

  def get_user_applications(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  def revoke_application_token(_parent, %{app_token_id: app_token_id}, %{
        context: %{current_user: %User{id: user_id}}
      }) do
    case ApplicationManager.get_application_token(app_token_id) do
      %ApplicationToken{user_id: ^user_id} = app_token ->
        case Applications.revoke_application_token(app_token) do
          {:ok, %{delete_app_token: app_token, delete_guardian_tokens: _delete_guardian_tokens}} ->
            {:ok, %{id: app_token.id}}

          {:error, _, _, _} ->
            {:error, dgettext("errors", "Error while revoking token")}
        end

      _ ->
        {:error, :application_token_not_found}
    end
  end

  def revoke_application_token(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  def activate_device(_parent, %{user_code: user_code}, %{
        context: %{current_user: %User{} = user}
      }) do
    case Applications.activate_device(user_code, user) do
      {:ok, %ApplicationDeviceActivation{} = app_device_activation} ->
        {:ok, app_device_activation |> Map.from_struct() |> Map.take([:application, :id, :scope])}

      {:error, :expired} ->
        {:error,
         %Error{
           message: dgettext("errors", "The given user code has expired"),
           status_code: 400,
           code: :device_application_code_expired
         }}

      {:error, :not_found} ->
        {:error, dgettext("errors", "The given user code is invalid")}
    end
  end

  def activate_device(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  @spec authorize_device_application(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, map()} | {:error, String.t()}
  def authorize_device_application(
        _parent,
        %{client_id: client_id, user_code: user_code},
        %{context: %{current_user: %User{}}}
      ) do
    case Applications.autorize_device_application(client_id, user_code) do
      {:ok, %ApplicationDeviceActivation{application: app}} ->
        {:ok, app}

      {:error, :not_confirmed} ->
        {:error,
         dgettext(
           "errors",
           "The device user code was not provided before approving the application"
         )}

      {:error, :not_found} ->
        {:error,
         dgettext(
           "errors",
           "The given user code is invalid"
         )}

      {:error, :expired} ->
        {:error,
         %Error{
           message: dgettext("errors", "The given user code has expired"),
           status_code: 400,
           code: :device_application_code_expired
         }}
    end
  end

  def authorize_device_application(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end
end
