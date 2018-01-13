defmodule Eventos.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Eventos.Repo
  import Logger

  alias Eventos.Accounts.Account

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id) do
    account = Repo.get!(Account, id)
  end

  def get_account_with_everything!(id) do
    account = Repo.get!(Account, id)
    |> Repo.preload :organized_events
  end

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{source: %Account{}}

  """
  def change_account(%Account{} = account) do
    Account.changeset(account, %{})
  end

  alias Eventos.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def list_users_with_accounts do
    Repo.all(User)
    |> Repo.preload :account
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_with_account!(id) do
    Repo.get!(User, id)
    |> Repo.preload :account
  end

  @doc """
  Get an user by email
  """
  def find_by_email(email) do
    user = Repo.get_by(User, email: email)
    |> Repo.preload :account
  end

  @doc """
  Authenticate user
  """
  def authenticate(%{user: user, password: password}) do
    # Does password match the one stored in the database?
    case Comeonin.Argon2.checkpw(password, user.password_hash) do
      true ->
        # Yes, create and return the token
        EventosWeb.Guardian.encode_and_sign(user)
      _ ->
        # No, return an error
        {:error, :unauthorized}
    end
  end

  @doc """
  Register user
  """
  def register(%{email: email, password: password, username: username}) do
    {:ok, {privkey, pubkey}} = RsaEx.generate_keypair("4096")


    account = Eventos.Accounts.Account.registration_changeset(%Eventos.Accounts.Account{}, %{
      username: username,
      domain: nil,
      private_key: privkey,
      public_key: pubkey,
      uri: "h",
      url: "h"
    })

    user = Eventos.Accounts.User.registration_changeset(%Eventos.Accounts.User{}, %{
      email: email,
      password: password
    })


    account_with_user = Ecto.Changeset.put_assoc(account, :user, user)

    try do
      coucou = Eventos.Repo.insert!(account_with_user)
      user = find_by_email(email)
      {:ok, user}
    rescue
     e in Ecto.InvalidChangesetError ->
      Logger.debug(inspect e)
      {:error, e.changeset.changes.user.errors}
    end

#    with {:ok, %Account{} = account} <- create_account(%{username: username, suspended: false, domain: nil, private_key: privkey, public_key: pubkey, uri: "h", url: "h"}) do
#      case create_user(%{email: email, password: password, account: account}) do
#        {:ok, %User{} = user } ->
#          {:ok, user}
#        {:error, %Ecto.Changeset{} = changeset} ->
#          {:error, changeset}
#      end
#    end
  end


  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
