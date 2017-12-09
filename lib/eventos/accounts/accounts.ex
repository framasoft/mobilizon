defmodule Eventos.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Logger
  alias Eventos.Repo

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


  @doc """
  Get an user by email
  """
  def find(email) do
    Repo.get_by!(User, email: email)
  end

  @doc """
  Authenticate user
  """
  def authenticate(%{user: user, password: password}) do
    # Does password match the one stored in the database?
    Logger.debug(user.password_hash)
    Logger.debug(password)
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
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
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
  def get_account!(id), do: Repo.get!(Account, id)

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

  alias Eventos.Accounts.Group

  @doc """
  Returns the list of groups.

  ## Examples

      iex> list_groups()
      [%Group{}, ...]

  """
  def list_groups do
    Repo.all(Group)
  end

  @doc """
  Gets a single group.

  Raises `Ecto.NoResultsError` if the Group does not exist.

  ## Examples

      iex> get_group!(123)
      %Group{}

      iex> get_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_group!(id), do: Repo.get!(Group, id)

  @doc """
  Creates a group.

  ## Examples

      iex> create_group(%{field: value})
      {:ok, %Group{}}

      iex> create_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a group.

  ## Examples

      iex> update_group(group, %{field: new_value})
      {:ok, %Group{}}

      iex> update_group(group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Group.

  ## Examples

      iex> delete_group(group)
      {:ok, %Group{}}

      iex> delete_group(group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking group changes.

  ## Examples

      iex> change_group(group)
      %Ecto.Changeset{source: %Group{}}

  """
  def change_group(%Group{} = group) do
    Group.changeset(group, %{})
  end

  alias Eventos.Accounts.GroupAccount

  @doc """
  Returns the list of group_accounts.

  ## Examples

      iex> list_group_accounts()
      [%GroupAccount{}, ...]

  """
  def list_group_accounts do
    Repo.all(GroupAccount)
  end

  @doc """
  Gets a single group_account.

  Raises `Ecto.NoResultsError` if the Group account does not exist.

  ## Examples

      iex> get_group_account!(123)
      %GroupAccount{}

      iex> get_group_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_group_account!(id), do: Repo.get!(GroupAccount, id)

  @doc """
  Creates a group_account.

  ## Examples

      iex> create_group_account(%{field: value})
      {:ok, %GroupAccount{}}

      iex> create_group_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group_account(attrs \\ %{}) do
    %GroupAccount{}
    |> GroupAccount.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a group_account.

  ## Examples

      iex> update_group_account(group_account, %{field: new_value})
      {:ok, %GroupAccount{}}

      iex> update_group_account(group_account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_group_account(%GroupAccount{} = group_account, attrs) do
    group_account
    |> GroupAccount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a GroupAccount.

  ## Examples

      iex> delete_group_account(group_account)
      {:ok, %GroupAccount{}}

      iex> delete_group_account(group_account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group_account(%GroupAccount{} = group_account) do
    Repo.delete(group_account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking group_account changes.

  ## Examples

      iex> change_group_account(group_account)
      %Ecto.Changeset{source: %GroupAccount{}}

  """
  def change_group_account(%GroupAccount{} = group_account) do
    GroupAccount.changeset(group_account, %{})
  end

  alias Eventos.Accounts.GroupRequest

  @doc """
  Returns the list of group_request.

  ## Examples

      iex> list_group_requests()
      [%GroupRequest{}, ...]

  """
  def list_group_requests do
    Repo.all(GroupRequest)
  end

  @doc """
  Gets a single group_request.

  Raises `Ecto.NoResultsError` if the Group request does not exist.

  ## Examples

      iex> get_group_request!(123)
      %GroupRequest{}

      iex> get_group_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_group_request!(id), do: Repo.get!(GroupRequest, id)

  @doc """
  Creates a group_request.

  ## Examples

      iex> create_group_request(%{field: value})
      {:ok, %GroupRequest{}}

      iex> create_group_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group_request(attrs \\ %{}) do
    %GroupRequest{}
    |> GroupRequest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a group_request.

  ## Examples

      iex> update_group_request(group_request, %{field: new_value})
      {:ok, %GroupRequest{}}

      iex> update_group_request(group_request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_group_request(%GroupRequest{} = group_request, attrs) do
    group_request
    |> GroupRequest.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a GroupRequest.

  ## Examples

      iex> delete_group_request(group_request)
      {:ok, %GroupRequest{}}

      iex> delete_group_request(group_request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_group_request(%GroupRequest{} = group_request) do
    Repo.delete(group_request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking group_request changes.

  ## Examples

      iex> change_group_request(group_request)
      %Ecto.Changeset{source: %GroupRequest{}}

  """
  def change_group_request(%GroupRequest{} = group_request) do
    GroupRequest.changeset(group_request, %{})
  end
end
