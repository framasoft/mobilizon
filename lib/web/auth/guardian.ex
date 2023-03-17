defmodule Mobilizon.Web.Auth.Guardian do
  @moduledoc """
  Handles the JWT tokens encoding and decoding
  """

  use Guardian,
    otp_app: :mobilizon,
    permissions: %{
      superuser: [:moderate, :super],
      user: [:base]
    }

  alias Mobilizon.{Applications, Users}
  alias Mobilizon.Applications.ApplicationToken
  alias Mobilizon.Users.User

  require Logger

  @spec subject_for_token(any(), any()) :: {:ok, String.t()} | {:error, :unknown_resource}
  def subject_for_token(%User{id: user_id}, _claims) do
    {:ok, "User:" <> to_string(user_id)}
  end

  def subject_for_token(%ApplicationToken{id: app_token_id}, _claims) do
    {:ok, "AppToken:" <> to_string(app_token_id)}
  end

  def subject_for_token(_, _) do
    {:error, :unknown_resource}
  end

  @spec resource_from_claims(any) ::
          {:error, :invalid_id | :no_result | :no_claims} | {:ok, Mobilizon.Users.User.t()}
  def resource_from_claims(%{"sub" => "User:" <> uid_str}) do
    Logger.debug(fn -> "Receiving claim for user #{uid_str}" end)

    try do
      case Integer.parse(uid_str) do
        {uid, ""} ->
          {:ok, Users.get_user_with_actors!(uid)}

        _ ->
          {:error, :invalid_id}
      end
    rescue
      e in Ecto.NoResultsError ->
        Logger.warn("Received token claim for non existing user: #{inspect(e)}")
        {:error, :no_result}
    end
  end

  def resource_from_claims(%{"sub" => "AppToken:" <> id_str}) do
    Logger.debug(fn -> "Receiving claim for app token #{id_str}" end)

    try do
      case Integer.parse(id_str) do
        {id, ""} ->
          application_token = Applications.get_application_token!(id)
          user = Users.get_user_with_actors!(application_token.user_id)
          application = Applications.get_application!(application_token.application_id)
          {:ok, application_token |> Map.put(:user, user) |> Map.put(:application, application)}

        _ ->
          {:error, :invalid_id}
      end
    rescue
      e in Ecto.NoResultsError ->
        Logger.info("Received token claim for non existing app token: #{inspect(e.message)}")
        {:error, :no_result}
    end
  end

  def resource_from_claims(_) do
    {:error, :no_claims}
  end

  @spec after_encode_and_sign(any(), any(), any(), any()) :: {:ok, String.t()}
  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  @spec on_verify(any(), any(), any()) :: {:ok, map()} | {:error, :token_not_found}
  def on_verify(claims, token, _options) do
    Logger.debug("[Guardian] Called on_verify")

    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  @spec on_revoke(any(), any(), any()) :: {:ok, map()} | {:error, :could_not_revoke_token}
  def on_revoke(claims, token, _options) do
    Logger.debug("[Guardian] Called on_revoke")

    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end

  @spec on_refresh({any(), any()}, {any(), any()}, any()) ::
          {:ok, {String.t(), map()}, {String.t(), map()}} | {:error, any()}
  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    Logger.debug("[Guardian] Called on_refresh")

    with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  @spec on_exchange(any(), any(), any()) ::
          {:ok, {String.t(), map()}, {String.t(), map()}} | {:error, any()}
  def on_exchange(old_stuff, new_stuff, options) do
    Logger.debug("[Guardian] Called on_exchange")
    on_refresh(old_stuff, new_stuff, options)
  end

  #  def build_claims(claims, _resource, opts) do
  #    claims = claims
  #             |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))
  #    {:ok, claims}
  #  end
end
