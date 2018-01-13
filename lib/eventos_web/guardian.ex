defmodule EventosWeb.Guardian do
  use Guardian, otp_app: :eventos, permissions: %{
    superuser: [:moderate, :super],
    user: [:base]
  }

  import Logger

  alias Eventos.Accounts
  alias Eventos.Accounts.{Account, User}

  def subject_for_token(user = %User{}, _claims) do
    {:ok, "User:" <> to_string(user.id)}
  end

  def subject_for_token(_, _) do
    {:error, :unknown_resource}
  end

  def resource_from_claims(%{"sub" => "User:" <> uid_str}) do
    try do
      Logger.debug("Inspecting resource token")
      Logger.debug(inspect uid_str)
      case Integer.parse(uid_str) do
        {uid, ""} ->
          {:ok, Accounts.get_user_with_account!(uid)}
        _ ->
          {:error, :invalid_id}
      end
    rescue
      Ecto.NoResultsError -> {:error, :no_result}
    end
  end

  def resource_from_claims(claims) do
    Logger.debug("Check bad resource")
    Logger.debug(inspect claims)
    {:error, :reason_for_error}
  end

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    Logger.debug(inspect claims)
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end

  #  def build_claims(claims, _resource, opts) do
  #    claims = claims
  #             |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))
  #    {:ok, claims}
  #  end
end