defmodule Mobilizon.Actors do
  @moduledoc """
  The Actors context.
  """

  import Ecto.Query
  import EctoEnum

  alias Ecto.Multi

  alias Mobilizon.Actors.{Actor, Bot, Follower, Member}
  alias Mobilizon.Crypto
  alias Mobilizon.Media.File
  alias Mobilizon.Storage.{Page, Repo}

  require Logger

  defenum(ActorType, :actor_type, [
    :Person,
    :Application,
    :Group,
    :Organization,
    :Service
  ])

  defenum(ActorOpenness, :actor_openness, [
    :invite_only,
    :moderated,
    :open
  ])

  defenum(ActorVisibility, :actor_visibility, [
    :public,
    :unlisted,
    # Probably unused
    :restricted,
    :private
  ])

  defenum(MemberRole, :member_role, [
    :not_approved,
    :member,
    :moderator,
    :administrator,
    :creator
  ])

  @doc false
  @spec data :: Dataloader.Ecto.t()
  def data, do: Dataloader.Ecto.new(Repo, query: &query/2)

  @doc false
  @spec query(Ecto.Query.t(), map) :: Ecto.Query.t()
  def query(queryable, _params), do: queryable

  @doc """
  Gets a single actor.
  """
  @spec get_actor(integer | String.t()) :: Actor.t() | nil
  def get_actor(id), do: Repo.get(Actor, id)

  @doc """
  Gets a single actor.
  Raises `Ecto.NoResultsError` if the Actor does not exist.
  """
  @spec get_actor!(integer | String.t()) :: Actor.t()
  def get_actor!(id), do: Repo.get!(Actor, id)

  @doc """
  Gets an actor with preloaded relations.
  """
  @spec get_actor_with_preload(integer | String.t()) :: Actor.t() | nil
  def get_actor_with_preload(id) do
    id
    |> actor_with_preload_query()
    |> Repo.one()
  end

  @doc """
  Gets a local actor with preloaded relations.
  """
  @spec get_local_actor_with_preload(integer | String.t()) :: Actor.t() | nil
  def get_local_actor_with_preload(id) do
    id
    |> actor_with_preload_query()
    |> filter_local()
    |> Repo.one()
  end

  @doc """
  Gets an actor by its URL (ActivityPub ID). The `:preload` option allows to
  preload the followers relation.
  """
  @spec get_actor_by_url(String.t(), boolean) ::
          {:ok, Actor.t()} | {:error, :actor_not_found}
  def get_actor_by_url(url, preload \\ false) do
    case Repo.get_by(Actor, url: url) do
      nil ->
        {:error, :actor_not_found}

      actor ->
        {:ok, preload_followers(actor, preload)}
    end
  end

  @doc """
  Gets an actor by its URL (ActivityPub ID). The `:preload` option allows to
  preload the followers relation.
  Raises `Ecto.NoResultsError` if the actor does not exist.
  """
  @spec get_actor_by_url!(String.t(), boolean) :: Actor.t()
  def get_actor_by_url!(url, preload \\ false) do
    Actor
    |> Repo.get_by!(url: url)
    |> preload_followers(preload)
  end

  @doc """
  Gets an actor by name.
  """
  @spec get_actor_by_name(String.t(), atom | nil) :: Actor.t() | nil
  def get_actor_by_name(name, type \\ nil) do
    from(a in Actor)
    |> filter_by_type(type)
    |> filter_by_name(String.split(name, "@"))
    |> Repo.one()
  end

  @doc """
  Gets a local actor by its preferred username.
  """
  @spec get_local_actor_by_name(String.t()) :: Actor.t() | nil
  def get_local_actor_by_name(name) do
    from(a in Actor)
    |> filter_by_name([name])
    |> Repo.one()
  end

  @doc """
  Gets a local actor by its preferred username and preloaded relations
  (organized events, followers and followings).
  """
  @spec get_local_actor_by_name_with_preload(String.t()) :: Actor.t() | nil
  def get_local_actor_by_name_with_preload(name) do
    name
    |> get_local_actor_by_name()
    |> Repo.preload([:organized_events, :followers, :followings])
  end

  @doc """
  Gets an actor by name and preloads the organized events.
  """
  @spec get_actor_by_name_with_preload(String.t(), atom() | nil) :: Actor.t() | nil
  def get_actor_by_name_with_preload(name, type \\ nil) do
    name
    |> get_actor_by_name(type)
    |> Repo.preload(:organized_events)
  end

  @doc """
  Gets a cached local actor by username.
  #TODO: move to MobilizonWeb layer
  """
  @spec get_cached_local_actor_by_name(String.t()) ::
          {:commit, Actor.t()} | {:ignore, any()}
  def get_cached_local_actor_by_name(name) do
    Cachex.fetch(:activity_pub, "actor_" <> name, fn "actor_" <> name ->
      case get_local_actor_by_name(name) do
        nil -> {:ignore, nil}
        %Actor{} = actor -> {:commit, actor}
      end
    end)
  end

  @doc """
  Gets local actors by their username.
  """
  @spec get_local_actor_by_username(String.t()) :: [Actor.t()]
  def get_local_actor_by_username(username) do
    username
    |> actor_by_username_query()
    |> filter_local()
    |> Repo.all()
    |> Repo.preload(:organized_events)
  end

  @doc """
  Builds a page struct for actors by their name or displayed name.
  """
  @spec build_actors_by_username_or_name_page(
          String.t(),
          [ActorType.t()],
          integer | nil,
          integer | nil
        ) :: Page.t()
  def build_actors_by_username_or_name_page(username, types, page \\ nil, limit \\ nil) do
    username
    |> actor_by_username_or_name_query()
    |> filter_by_types(types)
    |> Page.build_page(page, limit)
  end

  @doc """
  Creates an actor.
  """
  @spec create_actor(map) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def create_actor(attrs \\ %{}) do
    %Actor{}
    |> Actor.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an actor.
  """
  @spec update_actor(Actor.t(), map) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def update_actor(%Actor{} = actor, attrs) do
    actor
    |> Actor.update_changeset(attrs)
    |> delete_files_if_media_changed()
    |> Repo.update()
  end

  @doc """
  Upserts an actor.
  Conflicts on actor's URL/AP ID, replaces keys, avatar and banner, name and summary.
  """
  @spec upsert_actor(map, boolean) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def upsert_actor(%{keys: keys, name: name, summary: summary} = data, preload \\ false) do
    insert =
      data
      |> Actor.remote_actor_creation_changeset()
      |> Repo.insert(
        on_conflict: [set: [keys: keys, name: name, summary: summary]],
        conflict_target: [:url]
      )

    case insert do
      {:ok, actor} ->
        actor = if preload, do: Repo.preload(actor, [:followers]), else: actor

        {:ok, actor}

      error ->
        Logger.debug(inspect(error))

        {:error, error}
    end
  end

  @doc """
  Deletes an actor.
  """
  @spec delete_actor(Actor.t()) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def delete_actor(%Actor{domain: nil} = actor) do
    transaction =
      Multi.new()
      |> Multi.delete(:actor, actor)
      |> Multi.run(:remove_banner, fn _, %{actor: %Actor{}} -> remove_banner(actor) end)
      |> Multi.run(:remove_avatar, fn _, %{actor: %Actor{}} -> remove_avatar(actor) end)
      |> Repo.transaction()

    case transaction do
      {:ok, %{actor: %Actor{} = actor}} ->
        {:ok, actor}

      {:error, remove, error, _} when remove in [:remove_banner, :remove_avatar] ->
        {:error, error}
    end
  end

  def delete_actor(%Actor{} = actor), do: Repo.delete(actor)

  @doc """
  Returns the list of actors.
  """
  @spec list_actors :: [Actor.t()]
  def list_actors, do: Repo.all(Actor)

  @doc """
  Gets a group by its title.
  """
  @spec get_group_by_title(String.t()) :: Actor.t() | nil
  def get_group_by_title(title) do
    group_query()
    |> filter_by_name(String.split(title, "@"))
    |> Repo.one()
  end

  @doc """
  Gets a local group by its title.
  """
  @spec get_local_group_by_title(String.t()) :: Actor.t() | nil
  def get_local_group_by_title(title) do
    group_query()
    |> filter_by_name([title])
    |> Repo.one()
  end

  @spec actor_with_preload_query(integer | String.t()) :: Ecto.Query.t()
  defp actor_with_preload_query(id) do
    from(
      a in Actor,
      where: a.id == ^id,
      preload: [:organized_events, :followers, :followings]
    )
  end

  @spec actor_by_username_query(String.t()) :: Ecto.Query.t()
  defp actor_by_username_query(username) do
    from(
      a in Actor,
      where:
        fragment(
          "f_unaccent(?) <% f_unaccent(?) or f_unaccent(coalesce(?, '')) <% f_unaccent(?)",
          a.preferred_username,
          ^username,
          a.name,
          ^username
        ),
      order_by:
        fragment(
          "word_similarity(?, ?) + word_similarity(coalesce(?, ''), ?) desc",
          a.preferred_username,
          ^username,
          a.name,
          ^username
        )
    )
  end

  @spec actor_by_username_or_name_query(String.t()) :: Ecto.Query.t()
  defp actor_by_username_or_name_query(username) do
    from(
      a in Actor,
      where:
        fragment(
          "f_unaccent(?) %> f_unaccent(?) or f_unaccent(coalesce(?, '')) %> f_unaccent(?)",
          a.preferred_username,
          ^username,
          a.name,
          ^username
        ),
      order_by:
        fragment(
          "word_similarity(?, ?) + word_similarity(coalesce(?, ''), ?) desc",
          a.preferred_username,
          ^username,
          a.name,
          ^username
        )
    )
  end

  @spec group_query :: Ecto.Query.t()
  defp group_query do
    from(a in Actor, where: a.type == "Group")
  end

  @spec filter_local(Ecto.Query.t()) :: Ecto.Query.t()
  defp filter_local(query) do
    from(a in query, where: is_nil(a.domain))
  end

  @spec filter_by_type(Ecto.Query.t(), ActorType.t()) :: Ecto.Query.t()
  defp filter_by_type(query, type) when type in [:Person, :Group] do
    from(a in query, where: a.type == ^type)
  end

  defp filter_by_type(query, _type), do: query

  @spec filter_by_types(Ecto.Query.t(), [ActorType.t()]) :: Ecto.Query.t()
  defp filter_by_types(query, types) do
    from(a in query, where: a.type in ^types)
  end

  @spec filter_by_name(Ecto.Query.t(), [String.t()]) :: Ecto.Query.t()
  defp filter_by_name(query, [name]) do
    from(a in query, where: a.preferred_username == ^name and is_nil(a.domain))
  end

  defp filter_by_name(query, [name, domain]) do
    from(a in query, where: a.preferred_username == ^name and a.domain == ^domain)
  end

  @spec preload_followers(Actor.t(), boolean) :: Actor.t()
  defp preload_followers(actor, true), do: Repo.preload(actor, [:followers])
  defp preload_followers(actor, false), do: actor

  ##### TODO: continue refactoring from here #####

  @doc """
  Returns the groups an actor is member of
  """
  @spec get_groups_member_of(struct()) :: list()
  def get_groups_member_of(%Actor{id: actor_id}) do
    Repo.all(
      from(
        a in Actor,
        join: m in Member,
        on: a.id == m.parent_id,
        where: m.actor_id == ^actor_id
      )
    )
  end

  @doc """
  Returns the members for a group actor
  """
  @spec get_members_for_group(struct()) :: list()
  def get_members_for_group(%Actor{id: actor_id}) do
    Repo.all(
      from(
        a in Actor,
        join: m in Member,
        on: a.id == m.actor_id,
        where: m.parent_id == ^actor_id
      )
    )
  end

  @doc """
  Creates a group.

  ## Examples

      iex> create_group(%{name: "group name"})
      {:ok, %Mobilizon.Actors.Actor{}}

      iex> create_group(%{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_group(attrs \\ %{}) do
    %Actor{}
    |> Actor.group_creation(attrs)
    |> Repo.insert()
  end

  @doc """
  Delete a group
  """
  def delete_group!(%Actor{type: :Group} = group) do
    Repo.delete!(group)
  end

  @doc """
  List the groups
  """
  @spec list_groups(number(), number()) :: list(Actor.t())
  def list_groups(page \\ nil, limit \\ nil) do
    Repo.all(
      from(
        a in Actor,
        where: a.type == ^:Group,
        where: a.visibility in [^:public, ^:unlisted]
      )
      |> Page.paginate(page, limit)
    )
  end

  @doc """
  Get a group by its actor id
  """
  def get_group_by_actor_id(actor_id) do
    case Repo.get_by(Actor, id: actor_id, type: :Group) do
      nil -> {:error, :group_not_found}
      actor -> {:ok, actor}
    end
  end

  @doc """
  Create a new person actor
  """
  @spec new_person(map()) :: {:ok, Actor.t()} | any
  def new_person(args) do
    args = Map.put(args, :keys, Crypto.generate_rsa_2048_private_key())

    with {:ok, %Actor{} = person} <-
           %Actor{}
           |> Actor.registration_changeset(args)
           |> Repo.insert() do
      Mobilizon.Events.create_feed_token(%{"user_id" => args["user_id"], "actor_id" => person.id})
      {:ok, person}
    end
  end

  @doc """
  Register a new bot actor.
  """
  @spec register_bot_account(map()) :: Actor.t()
  def register_bot_account(%{name: name, summary: summary}) do
    actor =
      Mobilizon.Actors.Actor.registration_changeset(%Mobilizon.Actors.Actor{}, %{
        preferred_username: name,
        domain: nil,
        keys: Crypto.generate_rsa_2048_private_key(),
        summary: summary,
        type: :Service
      })

    try do
      Repo.insert!(actor)
    rescue
      e in Ecto.InvalidChangesetError ->
        {:error, e.changeset}
    end
  end

  def get_or_create_service_actor_by_url(url, preferred_username \\ "relay") do
    case get_actor_by_url(url) do
      {:ok, %Actor{} = actor} ->
        {:ok, actor}

      _ ->
        %{url: url, preferred_username: preferred_username}
        |> Actor.relay_creation_changeset()
        |> Repo.insert()
    end
  end

  @doc """
  Gets a single member of an actor (for example a group)
  """
  def get_member(actor_id, parent_id) do
    case Repo.get_by(Member, actor_id: actor_id, parent_id: parent_id) do
      nil -> {:error, :member_not_found}
      member -> {:ok, member}
    end
  end

  @doc """
  Gets a single member.

  Raises `Ecto.NoResultsError` if the Member does not exist.

  ## Examples

      iex> get_member!(123)
      %Mobilizon.Actors.Member{}

      iex> get_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_member!(id), do: Repo.get!(Member, id)

  @doc """
  Creates a member.

  ## Examples

      iex> create_member(%{actor: %Actor{}})
      {:ok, %Mobilizon.Actors.Member{}}

      iex> create_member(%{actor: nil})
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

      iex> update_member(%Member{}, %{role: 3})
      {:ok, %Mobilizon.Actors.Member{}}

      iex> update_member(%Member{}, %{role: nil})
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

      iex> delete_member(%Member{})
      {:ok, %Mobilizon.Actors.Member{}}

      iex> delete_member(%Member{})
      {:error, %Ecto.Changeset{}}

  """
  def delete_member(%Member{} = member) do
    Repo.delete(member)
  end

  @doc """
  Returns the list of administrator members for a group.
  """
  def list_administrator_members_for_group(id, page \\ nil, limit \\ nil) do
    Repo.all(
      from(
        m in Member,
        where: m.parent_id == ^id and (m.role == ^:creator or m.role == ^:administrator),
        preload: [:actor]
      )
      |> Page.paginate(page, limit)
    )
  end

  @doc """
  Get all group ids where the actor_id is the last administrator
  """
  def list_group_id_where_last_administrator(actor_id) do
    in_query =
      from(
        m in Member,
        where: m.actor_id == ^actor_id and (m.role == ^:creator or m.role == ^:administrator),
        select: m.parent_id
      )

    Repo.all(
      from(
        m in Member,
        where: m.role == ^:creator or m.role == ^:administrator,
        join: m2 in subquery(in_query),
        on: m.parent_id == m2.parent_id,
        group_by: m.parent_id,
        select: m.parent_id,
        having: count(m.actor_id) == 1
      )
    )
  end

  @doc """
  Returns the memberships for an actor
  """
  @spec groups_memberships_for_actor(Actor.t()) :: list(Member.t())
  def groups_memberships_for_actor(%Actor{id: id} = _actor) do
    Repo.all(
      from(
        m in Member,
        where: m.actor_id == ^id,
        preload: [:parent]
      )
    )
  end

  @doc """
  Returns the memberships for a group
  """
  @spec memberships_for_group(Actor.t()) :: list(Member.t())
  def memberships_for_group(%Actor{type: :Group, id: id} = _group) do
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
      [%Mobilizon.Actors.Bot{}]

  """
  def list_bots do
    Repo.all(Bot)
  end

  @doc """
  Gets a single bot.

  Raises `Ecto.NoResultsError` if the Bot does not exist.

  ## Examples

      iex> get_bot!(123)
      %Mobilizon.Actors.Bot{}

      iex> get_bot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bot!(id), do: Repo.get!(Bot, id)

  @doc """
  Get the bot associated to an actor
  """
  @spec get_bot_by_actor(Actor.t()) :: Bot.t()
  def get_bot_by_actor(%Actor{} = actor) do
    Repo.get_by!(Bot, actor_id: actor.id)
  end

  @doc """
  Creates a bot.

  ## Examples

      iex> create_bot(%{source: "toto"})
      {:ok, %Mobilizon.Actors.Bot{}}

      iex> create_bot(%{source: nil})
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

      iex> update_bot(%Bot{}, %{source: "new"})
      {:ok, %Mobilizon.Actors.Bot{}}

      iex> update_bot(%Bot{}, %{source: nil})
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

      iex> delete_bot(%Bot{})
      {:ok, %Mobilizon.Actors.Bot{}}

      iex> delete_bot(%Bot{})
      {:error, %Ecto.Changeset{}}

  """
  def delete_bot(%Bot{} = bot) do
    Repo.delete(bot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bot changes.

  ## Examples

      iex> change_bot(%Bot{})
      %Ecto.Changeset{data: %Mobilizon.Actors.Bot{}}

  """
  def change_bot(%Bot{} = bot) do
    Bot.changeset(bot, %{})
  end

  @doc """
  Gets a single follower.

  Raises `Ecto.NoResultsError` if the Follower does not exist.

  ## Examples

      iex> get_follower!(123)
      %Mobilizon.Actors.Follower{}

      iex> get_follower!(456)
      ** (Ecto.NoResultsError)

  """
  def get_follower!(id) do
    Repo.get!(Follower, id)
    |> Repo.preload([:actor, :target_actor])
  end

  @doc """
  Get a follow by the followed actor and following actor
  """
  @spec get_follower(Actor.t(), Actor.t()) :: Follower.t()
  def get_follower(%Actor{id: followed_id}, %Actor{id: follower_id}) do
    Repo.one(
      from(f in Follower, where: f.target_actor_id == ^followed_id and f.actor_id == ^follower_id)
    )
  end

  @doc """
  Get a follow by the followed actor and following actor
  """
  @spec get_follow_by_url(String.t()) :: Follower.t()
  def get_follow_by_url(url) do
    Repo.one(
      from(f in Follower,
        where: f.url == ^url,
        preload: [:actor, :target_actor]
      )
    )
  end

  @doc """
  Get followers from an actor

  If actor A and C both follow actor B, actor B's followers are A and C
  """
  @spec get_followers(struct(), number(), number()) :: map()
  def get_followers(%Actor{id: actor_id} = _actor, page \\ nil, limit \\ nil) do
    query =
      from(
        a in Actor,
        join: f in Follower,
        on: a.id == f.actor_id,
        where: f.target_actor_id == ^actor_id
      )

    total = Task.async(fn -> Repo.aggregate(query, :count, :id) end)
    elements = Task.async(fn -> Repo.all(Page.paginate(query, page, limit)) end)

    %{total: Task.await(total), elements: Task.await(elements)}
  end

  @spec get_full_followers(struct()) :: list()
  def get_full_followers(%Actor{} = actor) do
    actor
    |> get_full_followers_query()
    |> Repo.all()
  end

  @spec get_full_external_followers(struct()) :: list()
  def get_full_external_followers(%Actor{} = actor) do
    actor
    |> get_full_followers_query()
    |> where([a], not is_nil(a.domain))
    |> Repo.all()
  end

  @doc """
  Get followings from an actor

  If actor A follows actor B and C, actor A's followings are B and B
  """
  @spec get_followings(struct(), number(), number()) :: list()
  def get_followings(%Actor{id: actor_id} = _actor, page \\ nil, limit \\ nil) do
    query =
      from(
        a in Actor,
        join: f in Follower,
        on: a.id == f.target_actor_id,
        where: f.actor_id == ^actor_id
      )

    total = Task.async(fn -> Repo.aggregate(query, :count, :id) end)
    elements = Task.async(fn -> Repo.all(Page.paginate(query, page, limit)) end)

    %{total: Task.await(total), elements: Task.await(elements)}
  end

  @spec get_full_followings(struct()) :: list()
  def get_full_followings(%Actor{id: actor_id} = _actor) do
    Repo.all(
      from(
        a in Actor,
        join: f in Follower,
        on: a.id == f.target_actor_id,
        where: f.actor_id == ^actor_id
      )
    )
  end

  defp get_full_followers_query(%Actor{id: actor_id} = _actor) do
    from(
      a in Actor,
      join: f in Follower,
      on: a.id == f.actor_id,
      where: f.target_actor_id == ^actor_id
    )
  end

  @doc """
  Creates a follower.

  ## Examples

      iex> create_follower(%{actor: %Actor{}})
      {:ok, %Mobilizon.Actors.Follower{}}

      iex> create_follower(%{actor: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_follower(attrs \\ %{}) do
    with {:ok, %Follower{} = follower} <-
           %Follower{}
           |> Follower.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(follower, [:actor, :target_actor])}
    end
  end

  @doc """
  Updates a follower.

  ## Examples

      iex> update_follower(Follower{}, %{approved: true})
      {:ok, %Mobilizon.Actors.Follower{}}

      iex> update_follower(Follower{}, %{approved: nil})
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

      iex> delete_follower(Follower{})
      {:ok, %Mobilizon.Actors.Follower{}}

      iex> delete_follower(Follower{})
      {:error, %Ecto.Changeset{}}

  """
  def delete_follower(%Follower{} = follower) do
    Repo.delete(follower)
  end

  @doc """
  Delete a follower by followed and follower actors

  ## Examples

      iex> delete_follower(%Actor{}, %Actor{})
      {:ok, %Mobilizon.Actors.Follower{}}

      iex> delete_follower(%Actor{}, %Actor{})
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_follower(Actor.t(), Actor.t()) ::
          {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def delete_follower(%Actor{} = followed, %Actor{} = follower) do
    get_follower(followed, follower) |> Repo.delete()
  end

  @doc """
  Make an actor follow another
  """
  @spec follow(struct(), struct(), boolean()) :: Follower.t() | {:error, String.t()}
  def follow(%Actor{} = followed, %Actor{} = follower, url \\ nil, approved \\ true) do
    with {:suspended, false} <- {:suspended, followed.suspended},
         # Check if followed has blocked follower
         {:already_following, false} <- {:already_following, following?(follower, followed)} do
      do_follow(follower, followed, approved, url)
    else
      {:already_following, %Follower{}} ->
        {:error, :already_following,
         "Could not follow actor: you are already following #{followed.preferred_username}"}

      {:suspended, _} ->
        {:error, :suspended,
         "Could not follow actor: #{followed.preferred_username} has been suspended"}
    end
  end

  @doc """
  Unfollow an actor (remove a `Mobilizon.Actors.Follower`)
  """
  @spec unfollow(struct(), struct()) :: {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def unfollow(%Actor{} = followed, %Actor{} = follower) do
    case {:already_following, following?(follower, followed)} do
      {:already_following, %Follower{} = follow} ->
        delete_follower(follow)

      {:already_following, false} ->
        {:error, "Could not unfollow actor: you are not following #{followed.preferred_username}"}
    end
  end

  @spec do_follow(struct(), struct(), boolean(), String.t()) ::
          {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  defp do_follow(%Actor{} = follower, %Actor{} = followed, approved, url) do
    Logger.info(
      "Making #{follower.preferred_username} follow #{followed.preferred_username} (approved: #{
        approved
      })"
    )

    create_follower(%{
      "actor_id" => follower.id,
      "target_actor_id" => followed.id,
      "approved" => approved,
      "url" => url
    })
  end

  @doc """
  Returns whether an actor is following another
  """
  @spec following?(struct(), struct()) :: Follower.t() | false
  def following?(
        %Actor{} = follower_actor,
        %Actor{} = followed_actor
      ) do
    case get_follower(followed_actor, follower_actor) do
      nil -> false
      %Follower{} = follow -> follow
    end
  end

  defp remove_banner(%Actor{banner: nil} = actor), do: {:ok, actor}

  defp remove_banner(%Actor{banner: %File{url: url}} = actor) do
    safe_remove_file(url, actor)
  end

  defp remove_avatar(%Actor{avatar: nil} = actor), do: {:ok, actor}

  defp remove_avatar(%Actor{avatar: %File{url: url}} = actor) do
    safe_remove_file(url, actor)
  end

  defp safe_remove_file(url, %Actor{} = actor) do
    case MobilizonWeb.Upload.remove(url) do
      {:ok, _value} ->
        {:ok, actor}

      {:error, error} ->
        Logger.error("Error while removing an upload file")
        Logger.debug(inspect(error))
        {:ok, actor}
    end
  end

  @spec delete_files_if_media_changed(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp delete_files_if_media_changed(%Ecto.Changeset{changes: changes, data: data} = changeset) do
    Enum.each([:avatar, :banner], fn key ->
      if Map.has_key?(changes, key) do
        with %Ecto.Changeset{changes: %{url: new_url}} <- changes[key],
             %{url: old_url} <- data |> Map.from_struct() |> Map.get(key),
             false <- new_url == old_url do
          MobilizonWeb.Upload.remove(old_url)
        end
      end
    end)

    changeset
  end
end
