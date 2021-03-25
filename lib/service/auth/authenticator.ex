defmodule Mobilizon.Service.Auth.Authenticator do
  @moduledoc """
  Module to handle authentification (currently through database or LDAP)
  """
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Auth.Guardian

  @type tokens :: %{
          required(:access_token) => String.t(),
          required(:refresh_token) => String.t()
        }

  @type tokens_with_user :: %{
          required(:access_token) => String.t(),
          required(:refresh_token) => String.t(),
          required(:user) => User.t()
        }

  def implementation do
    Mobilizon.Config.get(
      Mobilizon.Service.Auth.Authenticator,
      Mobilizon.Service.Auth.MobilizonAuthenticator
    )
  end

  @callback login(String.t(), String.t()) :: {:ok, User.t()} | {:error, any()}
  @spec login(String.t(), String.t()) :: {:ok, User.t()} | {:error, any()}
  def login(email, password), do: implementation().login(email, password)

  @callback can_change_email?(User.t()) :: boolean
  def can_change_email?(%User{} = user), do: implementation().can_change_email?(user)

  @callback can_change_password?(User.t()) :: boolean
  def can_change_password?(%User{} = user), do: implementation().can_change_password?(user)

  @spec has_password?(User.t()) :: boolean()
  def has_password?(%User{provider: provider}), do: is_nil(provider) or provider == "ldap"

  @spec can_reset_password?(User.t()) :: boolean()
  def can_reset_password?(%User{} = user), do: has_password?(user) && can_change_password?(user)

  @spec authenticate(String.t(), String.t()) :: {:ok, tokens_with_user()}
  def authenticate(email, password) do
    with {:ok, %User{} = user} <- login(email, password),
         {:ok, %{access_token: access_token, refresh_token: refresh_token}} <-
           generate_tokens(user) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token, user: user}}
    end
  end

  @doc """
  Generates access token and refresh token for an user.
  """
  @spec generate_tokens(User.t()) :: {:ok, tokens}
  def generate_tokens(user) do
    with {:ok, access_token} <- generate_access_token(user),
         {:ok, refresh_token} <- generate_refresh_token(user) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    end
  end

  @doc """
  Generates access token for an user.
  """
  @spec generate_access_token(User.t()) :: {:ok, String.t()}
  def generate_access_token(user) do
    with {:ok, access_token, _claims} <-
           Guardian.encode_and_sign(user, %{}, token_type: "access") do
      {:ok, access_token}
    end
  end

  @doc """
  Generates refresh token for an user.
  """
  @spec generate_refresh_token(User.t()) :: {:ok, String.t()}
  def generate_refresh_token(user) do
    with {:ok, refresh_token, _claims} <-
           Guardian.encode_and_sign(user, %{}, token_type: "refresh") do
      {:ok, refresh_token}
    end
  end

  @spec fetch_user(String.t()) :: User.t() | {:error, :user_not_found}
  def fetch_user(nil), do: {:error, :user_not_found}

  def fetch_user(email) when not is_nil(email) do
    with {:ok, %User{} = user} <- Users.get_user_by_email(email, activated: true) do
      user
    end
  end
end
