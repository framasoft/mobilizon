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

  @type ttl :: {
          pos_integer(),
          :second | :minute | :hour | :week
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

  @callback provider_name :: String.t() | nil
  def provider_name, do: implementation().provider_name()

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
  @spec generate_tokens(User.t() | ApplicationToken.t()) :: {:ok, tokens} | {:error, any()}
  def generate_tokens(user) do
    with {:ok, access_token} <- generate_access_token(user),
         {:ok, refresh_token} <- generate_refresh_token(user) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    end
  end

  @doc """
  Generates access token for an user.
  """
  @spec generate_access_token(User.t() | ApplicationToken.t(), ttl() | nil) ::
          {:ok, String.t()} | {:error, any()}
  def generate_access_token(user, ttl \\ nil) do
    with {:ok, access_token, _claims} <-
           Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: ttl) do
      {:ok, access_token}
    end
  end

  @doc """
  Generates refresh token for an user.
  """
  @spec generate_refresh_token(User.t() | ApplicationToken.t(), ttl() | nil) ::
          {:ok, String.t()} | {:error, any()}
  def generate_refresh_token(user, ttl \\ nil) do
    with {:ok, refresh_token, _claims} <-
           Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: ttl) do
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
