defmodule Mobilizon.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query
  import EctoEnum

  import Mobilizon.Storage.Ecto

  alias Ecto.Multi
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.FeedToken
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.{Setting, User}

  defenum(UserRole, :user_role, [:administrator, :moderator, :user])

  defenum(NotificationPendingNotificationDelay, none: 0, direct: 1, one_hour: 5, one_day: 10)

  @doc """
  Registers an user.
  """
  @spec register(map) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register(args) do
    with {:ok, %User{} = user} <-
           %User{}
           |> User.registration_changeset(args)
           |> Repo.insert() do
      Events.create_feed_token(%{user_id: user.id})

      {:ok, user}
    end
  end

  @spec create_external(String.t(), String.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_external(email, provider) do
    with {:ok, %User{} = user} <-
           %User{}
           |> User.auth_provider_changeset(%{email: email, provider: provider})
           |> Repo.insert() do
      Events.create_feed_token(%{user_id: user.id})

      {:ok, user}
    end
  end

  @doc """
  Gets a single user.
  Raises `Ecto.NoResultsError` if the user does not exist.
  """
  @spec get_user!(integer | String.t()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @spec get_user(integer | String.t() | nil) :: User.t() | nil
  def get_user(nil), do: nil
  def get_user(id), do: Repo.get(User, id)

  def get_user_with_settings!(id) do
    User
    |> Repo.get(id)
    |> Repo.preload([:settings])
  end

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
  Gets an user by its email.
  """
  @spec get_user_by_email!(String.t(), boolean | nil) :: User.t()
  def get_user_by_email!(email, activated \\ nil) do
    email
    |> user_by_email_query(activated)
    |> Repo.one!()
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

  @delete_user_default_options [reserve_email: true]

  @doc """
  Deletes an user.

  Options:
  * `reserve_email` whether to keep a record of the email so that the user can't register again
  """
  @spec delete_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(%User{id: user_id} = user, options \\ @delete_user_default_options) do
    delete_user_options = Keyword.merge(@delete_user_default_options, options)

    multi =
      Multi.new()
      |> Multi.delete_all(:settings, from(s in Setting, where: s.user_id == ^user_id))
      |> Multi.delete_all(:feed_tokens, from(f in FeedToken, where: f.user_id == ^user_id))

    multi =
      if Keyword.get(delete_user_options, :reserve_email, true) do
        Multi.update(multi, :user, User.delete_changeset(user))
      else
        Multi.delete(multi, :user, user)
      end

    case Repo.transaction(multi) do
      {:ok, %{user: %User{} = user}} ->
        {:ok, user}

      {:error, remove, error, _} when remove in [:settings, :feed_tokens] ->
        {:error, error}
    end
  end

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
  @spec list_users(String.t(), integer | nil, integer | nil, atom | nil, atom | nil) :: Page.t()
  def list_users(email \\ "", page \\ nil, limit \\ nil, sort \\ nil, direction \\ nil)

  def list_users("", page, limit, sort, direction) do
    User
    |> sort(sort, direction)
    |> preload([u], [:actors, :feed_tokens, :settings, :default_actor])
    |> Page.build_page(page, limit)
  end

  def list_users(email, page, limit, sort, direction) do
    User
    |> where([u], ilike(u.email, ^"%#{email}%"))
    |> sort(sort, direction)
    |> preload([u], [:actors, :feed_tokens, :settings, :default_actor])
    |> Page.build_page(page, limit)
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
  def count_users, do: Repo.one(from(u in User, select: count(u.id), where: u.disabled == false))

  @doc """
  Gets a settings for an user.

  Raises `Ecto.NoResultsError` if the Setting does not exist.

  ## Examples

      iex> get_setting!(123)
      %Setting{}

      iex> get_setting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_setting!(user_id), do: Repo.get!(Setting, user_id)

  @spec get_setting(User.t()) :: Setting.t()
  def get_setting(%User{id: user_id}), do: get_setting(user_id)

  @spec get_setting(String.t() | integer()) :: Setting.t()
  def get_setting(user_id), do: Repo.get(Setting, user_id)

  @doc """
  Creates a setting.

  ## Examples

      iex> create_setting(%{field: value})
      {:ok, %Setting{}}

      iex> create_setting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_setting(attrs \\ %{}) do
    %Setting{}
    |> Setting.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:user_id, :inserted_at]},
      conflict_target: :user_id
    )
  end

  @doc """
  Updates a setting.

  ## Examples

      iex> update_setting(setting, %{field: new_value})
      {:ok, %Setting{}}

      iex> update_setting(setting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_setting(%Setting{} = setting, attrs) do
    setting
    |> Setting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a setting.

  ## Examples

      iex> delete_setting(setting)
      {:ok, %Setting{}}

      iex> delete_setting(setting)
      {:error, %Ecto.Changeset{}}

  """
  def delete_setting(%Setting{} = setting) do
    Repo.delete(setting)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking setting changes.

  ## Examples

      iex> change_setting(setting)
      %Ecto.Changeset{source: %Setting{}}

  """
  def change_setting(%Setting{} = setting) do
    Setting.changeset(setting, %{})
  end

  @spec user_by_email_query(String.t(), boolean | nil) :: Ecto.Query.t()
  defp user_by_email_query(email, nil) do
    from(u in User,
      where: u.email == ^email or u.unconfirmed_email == ^email,
      preload: :default_actor
    )
  end

  defp user_by_email_query(email, true) do
    from(
      u in User,
      where: u.email == ^email and not is_nil(u.confirmed_at) and not u.disabled,
      preload: :default_actor
    )
  end

  defp user_by_email_query(email, false) do
    from(
      u in User,
      where: (u.email == ^email or u.unconfirmed_email == ^email) and is_nil(u.confirmed_at),
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
