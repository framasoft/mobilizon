defmodule Mobilizon.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false

  alias Mobilizon.Repo
  import Mobilizon.Ecto

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User

  @doc false
  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  @doc false
  def query(queryable, _params) do
    queryable
  end

  @doc """
  Register user
  """
  @spec register(map()) :: {:ok, User.t()} | {:error, String.t()}
  def register(%{email: _email, password: _password} = args) do
    with {:ok, %User{} = user} <-
           %User{}
           |> User.registration_changeset(args)
           |> Mobilizon.Repo.insert() do
      Mobilizon.Events.create_feed_token(%{"user_id" => user.id})
      {:ok, user}
    end
  end

  @doc """
  Gets an user by it's email

  ## Examples

      iex> get_user_by_email("test@test.tld", true)
      {:ok, %Mobilizon.Users.User{}}

      iex> get_user_by_email("test@notfound.tld", false)
      {:error, :user_not_found}
  """
  def get_user_by_email(email, activated \\ nil) do
    query =
      case activated do
        nil ->
          from(u in User, where: u.email == ^email, preload: :default_actor)

        true ->
          from(
            u in User,
            where: u.email == ^email and not is_nil(u.confirmed_at),
            preload: :default_actor
          )

        false ->
          from(
            u in User,
            where: u.email == ^email and is_nil(u.confirmed_at),
            preload: :default_actor
          )
      end

    case Repo.one(query) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Get an user by it's activation token
  """
  @spec get_user_by_activation_token(String.t()) :: Actor.t()
  def get_user_by_activation_token(token) do
    Repo.one(
      from(
        u in User,
        where: u.confirmation_token == ^token,
        preload: [:default_actor]
      )
    )
  end

  @doc """
  Get an user by it's reset password token
  """
  @spec get_user_by_reset_password_token(String.t()) :: Actor.t()
  def get_user_by_reset_password_token(token) do
    Repo.one(
      from(
        u in User,
        where: u.reset_password_token == ^token,
        preload: [:default_actor]
      )
    )
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(User{}, %{password: "coucou"})
      {:ok, %Mobilizon.Users.User{}}

      iex> update_user(User{}, %{password: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    with {:ok, %User{} = user} <-
           user
           |> User.changeset(attrs)
           |> Repo.update() do
      {:ok, Repo.preload(user, [:default_actor])}
    end
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(%User{email: "test@test.tld"})
      {:ok, %Mobilizon.Users.User{}}

      iex> delete_user(%User{})
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  # @doc """
  # Returns an `%Ecto.Changeset{}` for tracking user changes.

  # ## Examples

  #     iex> change_user(%Mobilizon.Users.User{})
  #     %Ecto.Changeset{data: %Mobilizon.Users.User{}}

  # """
  # def change_user(%User{} = user) do
  #   User.changeset(user, %{})
  # end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %Mobilizon.Users.User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Get an user with it's actors

  Raises `Ecto.NoResultsError` if the User does not exist.
  """
  @spec get_user_with_actors!(integer()) :: User.t()
  def get_user_with_actors!(id) do
    user = Repo.get!(User, id)
    Repo.preload(user, [:actors, :default_actor])
  end

  @doc """
  Get user with it's actors by ID
  """
  @spec get_user_with_actors(integer()) :: User.t()
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
  Returns the associated actor for an user, either the default set one or the first found
  """
  @spec get_actor_for_user(Mobilizon.Users.User.t()) :: Mobilizon.Actors.Actor.t()
  def get_actor_for_user(%Mobilizon.Users.User{} = user) do
    case Repo.one(
           from(
             a in Actor,
             join: u in User,
             on: u.default_actor_id == a.id,
             where: u.id == ^user.id
           )
         ) do
      nil ->
        case user
             |> get_actors_for_user() do
          [] -> nil
          actors -> hd(actors)
        end

      actor ->
        actor
    end
  end

  def get_actors_for_user(%User{id: user_id}) do
    Repo.all(from(a in Actor, where: a.user_id == ^user_id))
  end

  @doc """
  Authenticate user
  """
  def authenticate(%{user: user, password: password}) do
    # Does password match the one stored in the database?
    case Argon2.verify_pass(password, user.password_hash) do
      true ->
        # Yes, create and return the token
        with {:ok, tokens} <- generate_tokens(user), do: {:ok, tokens}

      _ ->
        # No, return an error
        {:error, :unauthorized}
    end
  end

  @doc """
  Generate access token and refresh token
  """
  def generate_tokens(user) do
    with {:ok, access_token} <- generate_access_token(user),
         {:ok, refresh_token} <- generate_refresh_token(user) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    end
  end

  def generate_access_token(user) do
    with {:ok, access_token, _claims} <-
           MobilizonWeb.Guardian.encode_and_sign(user, %{},
             token_type: "access",
             ttl: {5, :seconds}
           ) do
      {:ok, access_token}
    end
  end

  def generate_refresh_token(user) do
    with {:ok, refresh_token, _claims} <-
           MobilizonWeb.Guardian.encode_and_sign(user, %{},
             token_type: "refresh",
             ttl: {30, :days}
           ) do
      {:ok, refresh_token}
    end
  end

  def update_user_default_actor(user_id, actor_id) do
    with _ <-
           from(
             u in User,
             where: u.id == ^user_id,
             update: [
               set: [
                 default_actor_id: ^actor_id
               ]
             ]
           )
           |> Repo.update_all([]) do
      Repo.get!(User, user_id)
      |> Repo.preload([:default_actor])
    end
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%Mobilizon.Users.User{}]

  """
  def list_users(page \\ nil, limit \\ nil, sort \\ nil, direction \\ nil) do
    Repo.all(
      User
      |> paginate(page, limit)
      |> sort(sort, direction)
    )
  end

  @doc """
  Returns the list of administrators.

  ## Examples

      iex> list_admins()
      [%Mobilizon.Users.User{role: :administrator}]

  """
  def list_admins() do
    User
    |> where([u], u.role == ^:administrator)
    |> Repo.all()
  end

  @doc """
  Returns the list of moderators.

  ## Examples

      iex> list_moderators()
      [%Mobilizon.Users.User{role: :moderator}, %Mobilizon.Users.User{role: :administrator}]

  """
  def list_moderators() do
    User
    |> where([u], u.role in ^[:administrator, :moderator])
    |> Repo.all()
  end

  def count_users() do
    Repo.one(
      from(
        u in User,
        select: count(u.id)
      )
    )
  end
end
