defmodule Eventos.Actors do
  @moduledoc """
  The Actors context.
  """

  import Ecto.Query, warn: false
  alias Eventos.Repo

  alias Eventos.Actors.Actor
  alias Eventos.Actors

  alias Eventos.Service.ActivityPub

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
  Returns a text representation of a local actor like user@domain.tld
  """
  def actor_to_local_name_and_domain(actor) do
    "#{actor.preferred_username}@#{Application.get_env(:my, EventosWeb.Endpoint)[:url][:host]}"
  end

  @doc """
  Returns a webfinger representation of an actor
  """
  def actor_to_webfinger_s(actor) do
    "acct:#{actor_to_local_name_and_domain(actor)}"
  end

  alias Eventos.Actors.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def list_users_with_actors do
    users = Repo.all(User)
    Repo.preload(users, :actor)
  end

  defp blank?(""), do: nil
  defp blank?(n), do: n

  def insert_or_update_actor(data) do
    data =
      data
      |> Map.put(:name, blank?(data[:preferred_username]) || data[:name])

    cs = Actor.remote_actor_creation(data)
    Repo.insert(cs, on_conflict: [set: [public_key: data.public_key]], conflict_target: [:preferred_username, :domain])
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

  def get_user_with_actor!(id) do
    user = Repo.get!(User, id)
    Repo.preload(user, :actor)
  end

  def get_actor_by_url(url) do
    Repo.get_by(Actor, url: url)
  end

  def get_actor_by_name(name) do
    Repo.get_by!(Actor, preferred_username: name)
  end

  def get_local_actor_by_name(name) do
    Repo.one from a in Actor, where: a.preferred_username == ^name and is_nil(a.domain)
  end

  def get_or_fetch_by_url(url) do
    if actor = get_actor_by_url(url) do
      actor
    else
      ap_try = ActivityPub.make_actor_from_url(url)

      case ap_try do
        {:ok, actor} ->
          actor

        _ -> {:error, "Could not fetch by AP id"}
      end
    end
  end

  @doc """
  Get an user by email
  """
  def find_by_email(email) do
    user = Repo.get_by(User, email: email)
    Repo.preload(user, :actor)
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
    #{:ok, {privkey, pubkey}} = RsaEx.generate_keypair("4096")
    {:ok, rsa_priv_key} = ExPublicKey.generate_key()
    {:ok, rsa_pub_key} = ExPublicKey.public_key_from_private_key(rsa_priv_key)

    actor = Eventos.Actors.Actor.registration_changeset(%Eventos.Actors.Actor{}, %{
      preferred_username: username,
      domain: nil,
      private_key: rsa_priv_key |> ExPublicKey.pem_encode(),
      public_key: rsa_pub_key |> ExPublicKey.pem_encode(),
      url: EventosWeb.Endpoint.url() <> "/@" <> username,
    })

    user = Eventos.Actors.User.registration_changeset(%Eventos.Actors.User{}, %{
      email: email,
      password: password
    })


    actor_with_user = Ecto.Changeset.put_assoc(actor, :user, user)

    try do
      Eventos.Repo.insert!(actor_with_user)
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

  alias Eventos.Actors.Member

  @doc """
  Returns the list of members.

  ## Examples

      iex> list_members()
      [%Member{}, ...]

  """
  def list_members do
    Repo.all(Member)
  end

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
    %Member{}
    |> Member.changeset(attrs)
    |> Repo.insert()
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

end
