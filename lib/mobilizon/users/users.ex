defmodule Mobilizon.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query
  import EctoEnum

  import Mobilizon.Storage.Ecto

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.User

  @type tokens :: %{
          required(:access_token) => String.t(),
          required(:refresh_token) => String.t()
        }

  defenum(UserRole, :user_role, [:administrator, :moderator, :user])

  @doc """
  Registers an user.
  """
  @spec register(map) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register(%{email: _email, password: _password} = args) do
    with {:ok, %User{} = user} <-
           %User{}
           |> User.registration_changeset(args)
           |> Repo.insert() do
      Events.create_feed_token(%{"user_id" => user.id})

      {:ok, user}
    end
  end

  @doc """
  Gets a single user.
  Raises `Ecto.NoResultsError` if the user does not exist.
  """
  @spec get_user!(integer | String.t()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets an user by its email.
  """
  @spec get_user_by_email(String.t(), boolean | nil) ::
          {:ok, User.t()} | {:error, :user_not_found}
  def get_user_by_email(email, activated \\ nil) do
    query = user_by_email_query(email, activated)

    case Repo.one(query) do
      nil ->
        {:error, :user_not_found}

      user ->
        {:ok, user}
    end
  end

  @doc """
  Get an user by its activation token.
  """
  @spec get_user_by_activation_token(String.t()) :: Actor.t() | nil
  def get_user_by_activation_token(token) do
    token
    |> user_by_activation_token_query()
    |> Repo.one()
  end

  @doc """
  Get an user by its reset password token.
  """
  @spec get_user_by_reset_password_token(String.t()) :: Actor.t()
  def get_user_by_reset_password_token(token) do
    token
    |> user_by_reset_password_token_query()
    |> Repo.one()
  end

  @doc """
  Updates an user.
  """
  @spec update_user(User.t(), map) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs) do
    with {:ok, %User{} = user} <-
           user
           |> User.changeset(attrs)
           |> Repo.update() do
      {:ok, Repo.preload(user, [:default_actor])}
    end
  end

  @doc """
  Deletes an user.
  """
  @spec delete_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(%User{} = user), do: Repo.delete(user)

  @doc """
  Get an user with its actors
  Raises `Ecto.NoResultsError` if the user does not exist.
  """
  @spec get_user_with_actors!(integer | String.t()) :: User.t()
  def get_user_with_actors!(id) do
    id
    |> get_user!()
    |> Repo.preload([:actors, :default_actor])
  end

  @doc """
  Get user with its actors.
  """
  @spec get_user_with_actors(integer()) :: {:ok, User.t()} | {:error, String.t()}
  def get_user_with_actors(id) do
    case Repo.get(User, id) do
      nil ->
        {:error, "User with ID #{id} not found"}

      user ->
        user =
          user
          |> Repo.preload([:actors, :default_actor])
          |> Map.put(:actors, get_actors_for_user(user))

        {:ok, user}
    end
  end

  @doc """
  Gets the associated actor for an user, either the default set one or the first
  found.
  """
  @spec get_actor_for_user(User.t()) :: Actor.t() | nil
  def get_actor_for_user(%User{} = user) do
    actor =
      user
      |> actor_for_user_query()
      |> Repo.one()

    case actor do
      nil ->
        case get_actors_for_user(user) do
          [] ->
            nil

          actors ->
            hd(actors)
        end

      actor ->
        actor
    end
  end

  @doc """
  Gets actors for an user.
  """
  @spec get_actors_for_user(User.t()) :: [Actor.t()]
  def get_actors_for_user(%User{} = user) do
    user
    |> actors_for_user_query()
    |> Repo.all()
  end

  @doc """
  Updates user's default actor.
  Raises `Ecto.NoResultsError` if the user does not exist.
  """
  @spec update_user_default_actor(integer | String.t(), integer | String.t()) :: User.t()
  def update_user_default_actor(user_id, actor_id) do
    with _ <-
           user_id
           |> update_user_default_actor_query(actor_id)
           |> Repo.update_all([]) do
      user_id
      |> get_user!()
      |> Repo.preload([:default_actor])
    end
  end

  @doc """
  Returns the list of users.
  """
  @spec list_users(integer | nil, integer | nil, atom | nil, atom | nil) :: [User.t()]
  def list_users(page \\ nil, limit \\ nil, sort \\ nil, direction \\ nil) do
    User
    |> Page.paginate(page, limit)
    |> sort(sort, direction)
    |> Repo.all()
  end

  @doc """
  Returns the list of administrators.
  """
  @spec list_admins :: [User.t()]
  def list_admins do
    User
    |> where([u], u.role == ^:administrator)
    |> Repo.all()
  end

  @doc """
  Returns the list of moderators.
  """
  @spec list_moderators :: [User.t()]
  def list_moderators do
    User
    |> where([u], u.role in ^[:administrator, :moderator])
    |> Repo.all()
  end

  @doc """
  Counts users.
  """
  @spec count_users :: integer
  def count_users, do: Repo.one(from(u in User, select: count(u.id)))

  @doc """
  Authenticate an user.
  """
  @spec authenticate(User.t()) :: {:ok, tokens} | {:error, :unauthorized}
  def authenticate(%{user: %User{password_hash: password_hash} = user, password: password}) do
    # Does password match the one stored in the database?
    if Argon2.verify_pass(password, password_hash) do
      {:ok, _tokens} = generate_tokens(user)
    else
      {:error, :unauthorized}
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
           MobilizonWeb.Guardian.encode_and_sign(user, %{}, token_type: "access") do
      {:ok, access_token}
    end
  end

  @doc """
  Generates refresh token for an user.
  """
  @spec generate_refresh_token(User.t()) :: {:ok, String.t()}
  def generate_refresh_token(user) do
    with {:ok, refresh_token, _claims} <-
           MobilizonWeb.Guardian.encode_and_sign(user, %{}, token_type: "refresh") do
      {:ok, refresh_token}
    end
  end

  @spec user_by_email_query(String.t(), boolean | nil) :: Ecto.Query.t()
  defp user_by_email_query(email, nil) do
    from(u in User, where: u.email == ^email, preload: :default_actor)
  end

  defp user_by_email_query(email, true) do
    from(
      u in User,
      where: u.email == ^email and not is_nil(u.confirmed_at),
      preload: :default_actor
    )
  end

  defp user_by_email_query(email, false) do
    from(
      u in User,
      where: u.email == ^email and is_nil(u.confirmed_at),
      preload: :default_actor
    )
  end

  @spec user_by_activation_token_query(String.t()) :: Ecto.Query.t()
  defp user_by_activation_token_query(token) do
    from(
      u in User,
      where: u.confirmation_token == ^token,
      preload: [:default_actor]
    )
  end

  @spec user_by_reset_password_token_query(String.t()) :: Ecto.Query.t()
  defp user_by_reset_password_token_query(token) do
    from(
      u in User,
      where: u.reset_password_token == ^token,
      preload: [:default_actor]
    )
  end

  @spec actor_for_user_query(User.t()) :: Ecto.Query.t()
  defp actor_for_user_query(%User{id: user_id}) do
    from(
      a in Actor,
      join: u in User,
      on: u.default_actor_id == a.id,
      where: u.id == ^user_id
    )
  end

  @spec actors_for_user_query(User.t()) :: Ecto.Query.t()
  defp actors_for_user_query(%User{id: user_id}) do
    from(a in Actor, where: a.user_id == ^user_id)
  end

  @spec update_user_default_actor_query(integer | String.t(), integer | String.t()) ::
          Ecto.Query.t()
  defp update_user_default_actor_query(user_id, actor_id) do
    from(
      u in User,
      where: u.id == ^user_id,
      update: [set: [default_actor_id: ^actor_id]]
    )
  end
end
