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

  alias Mobilizon.Users
  alias Mobilizon.Users.User

  require Logger

  def subject_for_token(%User{} = user, _claims) do
    {:ok, "User:" <> to_string(user.id)}
  end

  def subject_for_token(_, _) do
    {:error, :unknown_resource}
  end

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
      Ecto.NoResultsError -> {:error, :no_result}
    end
  end

  def resource_from_claims(_) do
    {:error, :reason_for_error}
  end

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  def on_exchange(old_stuff, new_stuff, options), do: on_refresh(old_stuff, new_stuff, options)

  #  def build_claims(claims, _resource, opts) do
  #    claims = claims
  #             |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))
  #    {:ok, claims}
  #  end
end
