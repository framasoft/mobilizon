defmodule Mobilizon.GraphQL.Resolvers.Application do
  @moduledoc """
  Handles the Application-related GraphQL calls.
  """

  alias Mobilizon.Applications, as: ApplicationManager
  alias Mobilizon.Applications.{Application, ApplicationDeviceActivation, ApplicationToken}
  alias Mobilizon.Service.Auth.Applications
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext, only: [dgettext: 2]

  require Logger

  @doc """
  Create an application
  """
  @spec authorize(any(), map(), Absinthe.Resolution.t()) :: {:ok, map()} | {:error, String.t()}
  def authorize(
        _parent,
        %{client_id: client_id, redirect_uri: redirect_uri, scope: scope, state: state},
        %{context: %{current_user: %User{id: user_id}}}
      ) do
    case Applications.autorize(client_id, redirect_uri, scope, user_id) do
      {:ok, code} ->
        {:ok, %{code: code, state: state}}

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
    {:error, dgettext("errors", "You need to be logged-in to autorize applications")}
  end

  @spec get_application(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, Application.t()} | {:error, :not_found | :unauthenticated}
  def get_application(_parent, %{client_id: client_id}, %{context: %{current_user: %User{}}}) do
    case ApplicationManager.get_application_by_client_id(client_id) do
      %Application{} = application ->
        {:ok, application}

      nil ->
        {:error, :not_found}
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
        {:error, :not_found}
    end
  end

  def revoke_application_token(_parent, _args, _resolution) do
    {:error, :unauthenticated}
  end

  def activate_device(_parent, %{user_code: user_code}, %{
        context: %{current_user: %User{} = user}
      }) do
    with {:ok, %ApplicationDeviceActivation{} = app_device_activation} <-
           Applications.activate_device(user_code, user) do
      {:ok, app_device_activation |> Map.from_struct() |> Map.take([:application, :id, :scope])}
    end
  end

  @spec authorize_device_application(any(), map(), Absinthe.Resolution.t()) ::
          {:ok, map()} | {:error, String.t()}
  def authorize_device_application(
        _parent,
        %{client_id: client_id, user_code: user_code},
        %{context: %{current_user: %User{id: user_id}}}
      ) do
    case Applications.autorize_device_application(client_id, user_code, user_id) do
      {:ok, %Application{} = app} ->
        {:ok, app}

      {:error, :application_not_found} ->
        {:error,
         dgettext(
           "errors",
           "No application with this client_id was found"
         )}
    end
  end
end
