defmodule Eventos.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Exgravatar

  alias Eventos.Repo
  alias Eventos.Accounts.Account
  alias Eventos.Accounts

  alias Eventos.Service.ActivityPub

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
    Repo.get!(Account, id)
  end

  def get_account_with_everything!(id) do
    account = Repo.get!(Account, id)
    Repo.preload(account, :organized_events)
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

  @doc """
  Returns a text representation of a local account like user@domain.tld
  """
  def account_to_local_username_and_domain(account) do
    "#{account.username}@#{Application.get_env(:my, EventosWeb.Endpoint)[:url][:host]}"
  end

  @doc """
  Returns a webfinger representation of an account
  """
  def account_to_webfinger_s(account) do
    "acct:#{account_to_local_username_and_domain(account)}"
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
    users = Repo.all(User)
    Repo.preload(users, :account)
  end

  defp blank?(""), do: nil
  defp blank?(n), do: n

  def insert_or_update_account(data) do
    data =
      data
      |> Map.put(:name, blank?(data[:display_name]) || data[:username])

    cs = Account.remote_account_creation(data)
    Repo.insert(cs, on_conflict: [set: [public_key: data.public_key]], conflict_target: [:username, :domain])
  end

#  def increase_event_count(%Account{} = account) do
#    event_count = (account.info["event_count"] || 0) + 1
#    new_info = Map.put(account.info, "note_count", note_count)
#
#    cs = info_changeset(account, %{info: new_info})
#
#    update_and_set_cache(cs)
#  end

  def count_users() do
    Repo.one(
      from u in User,
      select: count(u.id)
    )
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
    user = Repo.get!(User, id)
    Repo.preload(user, :account)
  end

  def get_account_by_url(url) do
    Repo.get_by(Account, url: url)
  end

  def get_account_by_username(username) do
    Repo.get_by!(Account, username: username)
  end

  def get_or_fetch_by_url(url) do
    if account = get_account_by_url(url) do
      account
    else
      ap_try = ActivityPub.make_account_from_url(url)

      case ap_try do
        {:ok, account} ->
          account

        _ -> {:error, "Could not fetch by AP id"}
      end
    end
  end

  @doc """
  Get an user by email
  """
  def find_by_email(email) do
    user = Repo.get_by(User, email: email)
    Repo.preload(user, :account)
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
  Fetch gravatar url for email and set it as avatar if it exists
  """
  defp gravatar(email) do
    url = gravatar_url(email, default: "404")
    case HTTPoison.get(url, [], [ssl: [{:versions, [:'tlsv1.2']}]]) do # See https://github.com/edgurgel/httpoison#note-about-broken-ssl-in-erlang-19
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        url
      _ -> # User doesn't have a gravatar email, or other issues
        nil
    end
  end

  @doc """
  Register user
  """
  def register(%{email: email, password: password, username: username}) do
    #{:ok, {privkey, pubkey}} = RsaEx.generate_keypair("4096")
    {:ok, rsa_priv_key} = ExPublicKey.generate_key()
    {:ok, rsa_pub_key} = ExPublicKey.public_key_from_private_key(rsa_priv_key)

    avatar = gravatar(email)
    account = Eventos.Accounts.Account.registration_changeset(%Eventos.Accounts.Account{}, %{
      username: username,
      domain: nil,
      private_key: rsa_priv_key |> ExPublicKey.pem_encode(),
      public_key: rsa_pub_key |> ExPublicKey.pem_encode(),
      url: EventosWeb.Endpoint.url() <> "/@" <> username,
    })

    user = Eventos.Accounts.User.registration_changeset(%Eventos.Accounts.User{}, %{
      email: email,
      password: password
    })


    account_with_user = Ecto.Changeset.put_assoc(account, :user, user)

    try do
      Eventos.Repo.insert!(account_with_user)
      user = find_by_email(email)
      {:ok, user}
    rescue
     e in Ecto.InvalidChangesetError ->
      {:error, e.changeset.changes.user.errors}
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
