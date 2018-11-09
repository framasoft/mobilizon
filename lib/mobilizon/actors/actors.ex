defmodule Mobilizon.Actors do
  @moduledoc """
  The Actors context.
  """

  import Ecto.Query, warn: false
  alias Mobilizon.Repo

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors

  alias Mobilizon.Service.ActivityPub

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end

  @doc """
  Returns the list of actors.

  ## Examples

      iex> list_actors()
      [%Actor{}, ...]

  """
  def list_actors do
    Repo.all(Actor)
  end

  @doc """
  Gets a single actor.

  Raises `Ecto.NoResultsError` if the Actor does not exist.

  ## Examples

      iex> get_actor!(123)
      %Actor{}

      iex> get_actor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_actor!(id) do
    Repo.get!(Actor, id)
  end

  @doc """
  Returns the associated actor for an user, either the default set one or the first found
  """
  @spec get_actor_for_user(%Mobilizon.Actors.User{}) :: %Mobilizon.Actors.Actor{}
  def get_actor_for_user(%Mobilizon.Actors.User{} = user) do
    case user.default_actor_id do
      nil -> get_first_actor_for_user(user)
      actor_id -> get_actor!(actor_id)
    end
  end

  @doc """
  Returns the first actor found for an user

  Useful when the user has not defined default actor

  Raises `Ecto.NoResultsError` if no Actor is found for this ID
  """
  defp get_first_actor_for_user(%Mobilizon.Actors.User{id: id} = _user) do
    Repo.one!(from(a in Actor, where: a.user_id == ^id))
  end

  def get_actor_with_everything!(id) do
    actor = Repo.get!(Actor, id)
    Repo.preload(actor, :organized_events)
  end

  @doc """
  Creates a actor.

  ## Examples

      iex> create_actor(%{field: value})
      {:ok, %Actor{}}

      iex> create_actor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_actor(attrs \\ %{}) do
    %Actor{}
    |> Actor.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a actor.

  ## Examples

      iex> update_actor(actor, %{field: new_value})
      {:ok, %Actor{}}

      iex> update_actor(actor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_actor(%Actor{} = actor, attrs) do
    actor
    |> Actor.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Actor.

  ## Examples

      iex> delete_actor(actor)
      {:ok, %Actor{}}

      iex> delete_actor(actor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_actor(%Actor{} = actor) do
    Repo.delete(actor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking actor changes.

  ## Examples

      iex> change_actor(actor)
      %Ecto.Changeset{source: %Actor{}}

  """
  def change_actor(%Actor{} = actor) do
    Actor.changeset(actor, %{})
  end

  @doc """
  List the groups
  """
  def list_groups do
    Repo.all(from(a in Actor, where: a.type == ^:Group))
  end

  def get_group_by_name(name) do
    case String.split(name, "@") do
      [name] ->
        Repo.get_by(Actor, preferred_username: name, type: :Group)

      [name, domain] ->
        Repo.get_by(Actor, preferred_username: name, domain: domain, type: :Group)
    end
  end

  @doc """
  Creates a group.

  ## Examples

      iex> create_group(%{field: value})
      {:ok, %Actor{}}

      iex> create_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group(attrs \\ %{}) do
    %Actor{}
    |> Actor.group_creation(attrs)
    |> Repo.insert()
  end

  alias Mobilizon.Actors.User

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
  List users with their associated actors. No reason for that, so removed
  """
  # def list_users_with_actors do
  #   users = Repo.all(User)
  #   Repo.preload(users, :actors)
  # end

  defp blank?(""), do: nil
  defp blank?(n), do: n

  def insert_or_update_actor(data) do
    cs = Actor.remote_actor_creation(data)

    actor =
      Repo.insert(
        cs,
        on_conflict: [
          set: [
            keys: data.keys,
            avatar_url: data.avatar_url,
            banner_url: data.banner_url,
            name: data.name
          ]
        ],
        conflict_target: [:preferred_username, :domain]
      )

    {:ok, actor}
  end

  #  def increase_event_count(%Actor{} = actor) do
  #    event_count = (actor.info["event_count"] || 0) + 1
  #    new_info = Map.put(actor.info, "note_count", note_count)
  #
  #    cs = info_changeset(actor, %{info: new_info})
  #
  #    update_and_set_cache(cs)
  #  end

  def count_users() do
    Repo.one(
      from(
        u in User,
        select: count(u.id)
      )
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

  def get_user_with_actor!(id) do
    user = Repo.get!(User, id)
    Repo.preload(user, :actors)
  end

  @spec get_user_with_actor(integer()) :: %User{}
  def get_user_with_actor(id) do
    case Repo.get(User, id) do
      nil -> {:error, "User with ID #{id} not found"}
      user -> {:ok, Repo.preload(user, :actors)}
    end
  end

  def get_actor_by_url(url) do
    Repo.get_by(Actor, url: url)
  end

  def get_actor_by_name(name) do
    actor =
      case String.split(name, "@") do
        [name] ->
          Repo.one(from(a in Actor, where: a.preferred_username == ^name and is_nil(a.domain)))

        [name, domain] ->
          Repo.get_by(Actor, preferred_username: name, domain: domain)
      end
  end

  def get_local_actor_by_name(name) do
    Repo.one(from(a in Actor, where: a.preferred_username == ^name and is_nil(a.domain)))
  end

  def get_local_actor_by_name_with_everything(name) do
    actor = Repo.one(from(a in Actor, where: a.preferred_username == ^name and is_nil(a.domain)))
    Repo.preload(actor, :organized_events)
  end

  def get_actor_by_name_with_everything(name) do
    actor =
      case String.split(name, "@") do
        [name] ->
          Repo.one(from(a in Actor, where: a.preferred_username == ^name and is_nil(a.domain)))

        [name, domain] ->
          Repo.one(from(a in Actor, where: a.preferred_username == ^name and a.domain == ^domain))
      end

    Repo.preload(actor, :organized_events)
  end

  def get_or_fetch_by_url(url) do
    if actor = get_actor_by_url(url) do
      {:ok, actor}
    else
      case ActivityPub.make_actor_from_url(url) do
        {:ok, actor} ->
          {:ok, actor}

        _ ->
          {:error, "Could not fetch by AP id"}
      end
    end
  end

  @doc """
  Find local users by it's username
  """
  def find_local_by_username(username) do
    actors =
      Repo.all(
        from(
          a in Actor,
          where:
            (ilike(a.preferred_username, ^like_sanitize(username)) or
               ilike(a.name, ^like_sanitize(username))) and is_nil(a.domain)
        )
      )

    Repo.preload(actors, :organized_events)
  end

  @doc """
  Find actors by their name or displayed name
  """
  def find_actors_by_username_or_name(username, page \\ 1, limit \\ 10)
  def find_actors_by_username_or_name("", page, limit), do: []

  def find_actors_by_username_or_name(username, page, limit) do
    start = (page - 1) * limit

    Repo.all(
      from(
        a in Actor,
        limit: ^limit,
        offset: ^start,
        where:
          ilike(a.preferred_username, ^like_sanitize(username)) or
            ilike(a.name, ^like_sanitize(username))
      )
    )
  end

  @doc """
  Sanitize the LIKE queries
  """
  defp like_sanitize(value) do
    "%" <> String.replace(value, ~r/([\\%_])/, "\\1") <> "%"
  end

  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
  def search(name) do
    # find already saved accounts
    case find_actors_by_username_or_name(name) do
      [] ->
        # no accounts found, let's test if it's an username@domain.tld
        with true <- Regex.match?(@email_regex, name),
             # creating the actor in that case
             {:ok, actor} <- ActivityPub.find_or_make_actor_from_nickname(name) do
          {:ok, [actor]}
        else
          false ->
            {:ok, []}

          # error fingering the actor
          {:error, err} ->
            {:error, err}
        end

      actors = [_ | _] ->
        # actors already saved found !
        {:ok, actors}
    end
  end

  @doc """
  Authenticate user
  """
  def authenticate(%{user: user, password: password}) do
    # Does password match the one stored in the database?
    case Comeonin.Argon2.checkpw(password, user.password_hash) do
      true ->
        # Yes, create and return the token
        MobilizonWeb.Guardian.encode_and_sign(user)

      _ ->
        # No, return an error
        {:error, :unauthorized}
    end
  end

  @doc """
  Register user
  """
  def register(%{email: email, password: password, username: username}) do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)
    pem = [entry] |> :public_key.pem_encode() |> String.trim_trailing()

    import Exgravatar

    avatar_url = gravatar_url(email, default: "404")

    avatar =
      case HTTPoison.get(avatar_url) do
        {:ok, %HTTPoison.Response{status_code: 200}} ->
          avatar_url

        _ ->
          nil
      end

    with actor_changeset <-
           Mobilizon.Actors.Actor.registration_changeset(%Mobilizon.Actors.Actor{}, %{
             preferred_username: username,
             domain: nil,
             keys: pem,
             avatar_url: avatar
           }),
         {:ok, %Mobilizon.Actors.Actor{id: id} = actor} <- Mobilizon.Repo.insert(actor_changeset),
         user_changeset <-
           Mobilizon.Actors.User.registration_changeset(%Mobilizon.Actors.User{}, %{
             email: email,
             password: password,
             default_actor_id: id
           }),
         {:ok, %Mobilizon.Actors.User{} = user} <- Mobilizon.Repo.insert(user_changeset) do
      {:ok, Map.put(actor, :user, user)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        handle_actor_user_changeset(changeset)
    end
  end

  defp handle_actor_user_changeset(changeset) do
    changeset =
      Ecto.Changeset.traverse_errors(changeset, fn
        {msg, opts} -> msg
        msg -> msg
      end)

    {:error, hd(Map.get(changeset, :email))}
  end

  def register_bot_account(%{name: name, summary: summary}) do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)
    pem = [entry] |> :public_key.pem_encode() |> String.trim_trailing()

    actor =
      Mobilizon.Actors.Actor.registration_changeset(%Mobilizon.Actors.Actor{}, %{
        preferred_username: name,
        domain: nil,
        keys: pem,
        summary: summary,
        type: :Service
      })

    try do
      Mobilizon.Repo.insert!(actor)
    rescue
      e in Ecto.InvalidChangesetError ->
        {:error, e.changeset}
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
  Gets an user by it's email

  ## Examples

      iex> get_user_by_email(user, email)
      {:ok, %User{}}

      iex> get_user_by_email(user, wrong_email)
      {:error, nil}
  """
  def get_user_by_email(email, activated \\ nil) do
    query =
      case activated do
        nil -> from(u in User, where: u.email == ^email)
        true -> from(u in User, where: u.email == ^email and not is_nil(u.confirmed_at))
        false -> from(u in User, where: u.email == ^email and is_nil(u.confirmed_at))
      end

    case Repo.one(query) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
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

  alias Mobilizon.Actors.Member

  @doc """
  Gets a single member.

  Raises `Ecto.NoResultsError` if the Member does not exist.

  ## Examples

      iex> get_member!(123)
      %Member{}

      iex> get_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_member!(id), do: Repo.get!(Member, id)

  @doc """
  Creates a member.

  ## Examples

      iex> create_member(%{field: value})
      {:ok, %Member{}}

      iex> create_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_member(attrs \\ %{}) do
    with {:ok, %Member{} = member} <-
           %Member{}
           |> Member.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(member, [:actor, :parent])}
    end
  end

  @doc """
  Updates a member.

  ## Examples

      iex> update_member(member, %{field: new_value})
      {:ok, %Member{}}

      iex> update_member(member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_member(%Member{} = member, attrs) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Member.

  ## Examples

      iex> delete_member(member)
      {:ok, %Member{}}

      iex> delete_member(member)
      {:error, %Ecto.Changeset{}}

  """
  def delete_member(%Member{} = member) do
    Repo.delete(member)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking member changes.

  ## Examples

      iex> change_member(member)
      %Ecto.Changeset{source: %Member{}}

  """
  def change_member(%Member{} = member) do
    Member.changeset(member, %{})
  end

  def groups_for_actor(%Actor{id: id} = _actor) do
    Repo.all(
      from(
        m in Member,
        where: m.actor_id == ^id,
        preload: [:parent]
      )
    )
  end

  def members_for_group(%Actor{type: :Group, id: id} = _group) do
    Repo.all(
      from(
        m in Member,
        where: m.parent_id == ^id,
        preload: [:parent, :actor]
      )
    )
  end

  alias Mobilizon.Actors.Bot

  @doc """
  Returns the list of bots.

  ## Examples

      iex> list_bots()
      [%Bot{}, ...]

  """
  def list_bots do
    Repo.all(Bot)
  end

  @doc """
  Gets a single bot.

  Raises `Ecto.NoResultsError` if the Bot does not exist.

  ## Examples

      iex> get_bot!(123)
      %Bot{}

      iex> get_bot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bot!(id), do: Repo.get!(Bot, id)

  @spec get_bot_by_actor(Actor.t()) :: Bot.t()
  def get_bot_by_actor(%Actor{} = actor) do
    Repo.get_by!(Bot, actor_id: actor.id)
  end

  @doc """
  Creates a bot.

  ## Examples

      iex> create_bot(%{field: value})
      {:ok, %Bot{}}

      iex> create_bot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bot(attrs \\ %{}) do
    %Bot{}
    |> Bot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bot.

  ## Examples

      iex> update_bot(bot, %{field: new_value})
      {:ok, %Bot{}}

      iex> update_bot(bot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bot(%Bot{} = bot, attrs) do
    bot
    |> Bot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Bot.

  ## Examples

      iex> delete_bot(bot)
      {:ok, %Bot{}}

      iex> delete_bot(bot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bot(%Bot{} = bot) do
    Repo.delete(bot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bot changes.

  ## Examples

      iex> change_bot(bot)
      %Ecto.Changeset{source: %Bot{}}

  """
  def change_bot(%Bot{} = bot) do
    Bot.changeset(bot, %{})
  end

  alias Mobilizon.Actors.Follower

  @doc """
  Gets a single follower.

  Raises `Ecto.NoResultsError` if the Follower does not exist.

  ## Examples

      iex> get_follower!(123)
      %Follower{}

      iex> get_follower!(456)
      ** (Ecto.NoResultsError)

  """
  def get_follower!(id) do
    Repo.get!(Follower, id)
    |> Repo.preload([:actor, :target_actor])
  end

  @doc """
  Creates a follower.

  ## Examples

      iex> create_follower(%{field: value})
      {:ok, %Follower{}}

      iex> create_follower(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_follower(attrs \\ %{}) do
    %Follower{}
    |> Follower.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a follower.

  ## Examples

      iex> update_follower(follower, %{field: new_value})
      {:ok, %Follower{}}

      iex> update_follower(follower, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_follower(%Follower{} = follower, attrs) do
    follower
    |> Follower.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Follower.

  ## Examples

      iex> delete_follower(follower)
      {:ok, %Follower{}}

      iex> delete_follower(follower)
      {:error, %Ecto.Changeset{}}

  """
  def delete_follower(%Follower{} = follower) do
    Repo.delete(follower)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking follower changes.

  ## Examples

      iex> change_follower(follower)
      %Ecto.Changeset{source: %Follower{}}

  """
  def change_follower(%Follower{} = follower) do
    Follower.changeset(follower, %{})
  end
end
