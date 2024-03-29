defmodule Mobilizon.Service.Auth.MobilizonAuthenticator do
  @moduledoc """
  Authenticate Mobilizon users through database accounts
  """
  alias Mobilizon.Users.User

  alias Mobilizon.Service.Auth.Authenticator

  import Authenticator,
    only: [fetch_user: 1]

  @behaviour Authenticator

  @impl Authenticator
  def login(email, password) do
    with {:user, %User{password_hash: password_hash, provider: nil} = user}
         when not is_nil(password_hash) <-
           {:user, fetch_user(email)},
         {:acceptable_password, true} <-
           {:acceptable_password, not (is_nil(password) || password == "")},
         {:checkpw, true} <- {:checkpw, Argon2.verify_pass(password, password_hash)} do
      {:ok, user}
    else
      {:user, %User{}} ->
        # User from a 3rd-party provider, doesn't have a password
        {:error, :user_not_found}

      {:user, {:error, :user_not_found}} ->
        {:error, :user_not_found}

      {:acceptable_password, false} ->
        {:error, :bad_password}

      {:checkpw, false} ->
        {:error, :bad_password}
    end
  end

  @impl Authenticator
  def can_change_email?(%User{provider: provider}), do: is_nil(provider)

  @impl Authenticator
  def can_change_password?(%User{provider: provider}), do: is_nil(provider)

  @impl Authenticator
  def provider_name, do: nil
end
