defmodule Mobilizon.Actors do
  @moduledoc """
  The Actors context.
  """

  import Ecto.Query

  alias Ecto.Multi

  alias Mobilizon.Actors.{Actor, Bot, Member, Follower}
  alias Mobilizon.Media.File
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Storage.{Page, Repo}

  require Logger

  @doc false
  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  @doc false
  def query(queryable, _params) do
    queryable
  end

  @doc """
  Returns the list of actors.

  ## Examples

      iex> Mobilizon.Actors.list_actors()
      [%Mobilizon.Actors.Actor{}]

  """
  @spec list_actors() :: list()
  def list_actors do
    Repo.all(Actor)
  end

  @doc """
  Gets a single actor.

  Raises `Ecto.NoResultsError` if the Actor does not exist.

  ## Examples

      iex> get_actor!(123)
      %Mobilizon.Actors.Actor{}

      iex> get_actor!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_actor!(integer()) :: Actor.t()
  def get_actor!(id) do
    Repo.get!(Actor, id)
  end

  def get_actor(id) do
    Repo.get(Actor, id)
  end

  # Get actor by ID and preload organized events, followers and followings
  @spec get_actor_with_everything(integer()) :: Ecto.Query.t()
  defp do_get_actor_with_everything(id) do
    from(a in Actor,
      where: a.id == ^id,
      preload: [:organized_events, :followers, :followings]
    )
  end

  @doc """
  Returns an actor with every relation
  """
  @spec get_actor_with_everything(integer()) :: Mobilizon.Actors.Actor.t()
  def get_actor_with_everything(id) do
    id
    |> do_get_actor_with_everything
    |> Repo.one()
  end

  @doc """
  Returns an actor with every relation
  """
  @spec get_local_actor_with_everything(integer()) :: Mobilizon.Actors.Actor.t()
  def get_local_actor_with_everything(id) do
    id
    |> do_get_actor_with_everything
    |> where([a], is_nil(a.domain))
    |> Repo.one()
  end

  @doc """
  Creates a actor.

  ## Examples

      iex> create_actor(%{preferred_username: "test"})
      {:ok, %Mobilizon.Actors.Actor{preferred_username: "test"}}

      iex> create_actor(%{preferred_username: nil})
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

      iex> update_actor(%Actor{preferred_username: "toto"}, %{preferred_username: "tata"})
      {:ok, %Mobilizon.Actors.Actor{preferred_username: "tata"}}

      iex> update_actor(%Actor{preferred_username: "toto"}, %{preferred_username: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_actor(%Actor{} = actor, attrs) do
    actor
    |> Actor.update_changeset(attrs)
    |> delete_files_if_media_changed()
    |> Repo.update()
  end

  defp delete_files_if_media_changed(%Ecto.Changeset{changes: changes} = changeset) do
    Enum.each([:avatar, :banner], fn key ->
      if Map.has_key?(changes, key) do
        with %Ecto.Changeset{changes: %{url: new_url}} <- changes[key],
             %{url: old_url} = _old_key <- Map.from_struct(changeset.data) |> Map.get(key),
             false <- new_url == old_url do
          MobilizonWeb.Upload.remove(old_url)
        end
      end
    end)

    changeset
  end

  @doc """
  Deletes a Actor.

  ## Examples

      iex> delete_actor(%Actor{})
      {:ok, %Mobilizon.Actors.Actor{}}

      iex> delete_actor(nil)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_actor(Actor.t()) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def delete_actor(%Actor{domain: nil} = actor) do
    case Multi.new()
         |> Multi.delete(:actor, actor)
         |> Multi.run(:remove_banner, fn _repo, %{actor: %Actor{}} = _picture ->
           remove_banner(actor)
         end)
         |> Multi.run(:remove_avatar, fn _repo, %{actor: %Actor{}} = _picture ->
           remove_avatar(actor)
         end)
         |> Repo.transaction() do
      {:ok, %{actor: %Actor{} = actor}} ->
        {:ok, actor}

      {:error, remove, error, _} when remove in [:remove_banner, :remove_avatar] ->
        {:error, error}
    end
  end

  def delete_actor(%Actor{} = actor) do
    Repo.delete(actor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking actor changes.

  ## Examples

      iex> change_actor(%Actor{})
      %Ecto.Changeset{data: %Mobilizon.Actors.Actor{}}

  """
  @spec change_actor(Actor.t()) :: Ecto.Changeset.t()
  def change_actor(%Actor{} = actor) do
    Actor.changeset(actor, %{})
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
  Get the default member role depending on the actor openness
  """
  @spec get_default_member_role(Actor.t()) :: atom()
  def get_default_member_role(%Actor{openness: :open}), do: :member
  def get_default_member_role(%Actor{}), do: :not_approved

  @doc """
  Get a group by it's title
  """
  @spec get_group_by_title(String.t()) :: Actor.t() | nil
  def get_group_by_title(title) do
    case String.split(title, "@") do
      [title] ->
        get_local_group_by_title(title)

      [title, domain] ->
        Repo.one(
          from(a in Actor,
            where: a.preferred_username == ^title and a.type == "Group" and a.domain == ^domain
          )
        )
    end
  end

  @doc """
  Get a local group by it's title
  """
  @spec get_local_group_by_title(String.t()) :: Actor.t() | nil
  def get_local_group_by_title(title) do
    title
    |> do_get_local_group_by_title
    |> Repo.one()
  end

  @spec do_get_local_group_by_title(String.t()) :: Ecto.Query.t()
  defp do_get_local_group_by_title(title) do
    from(a in Actor,
      where: a.preferred_username == ^title and a.type == "Group" and is_nil(a.domain)
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
  Upsert an actor.

  Conflicts on actor's URL/AP ID. Replaces keys, avatar and banner, name and summary.
  """
  @spec insert_or_update_actor(map(), boolean()) :: {:ok, Actor.t()}
  def insert_or_update_actor(data, preload \\ false) do
    cs =
      data
      |> Actor.remote_actor_creation()

    case Repo.insert(
           cs,
           on_conflict: [
             set: [
               keys: data.keys,
               name: data.name,
               summary: data.summary
             ]
           ],
           conflict_target: [:url]
         ) do
      {:ok, actor} ->
        actor = if preload, do: Repo.preload(actor, [:followers]), else: actor
        {:ok, actor}

      err ->
        Logger.debug(inspect(err))
        {:error, err}
    end
  end

  #  def increase_event_count(%Actor{} = actor) do
  #    event_count = (actor.info["event_count"] || 0) + 1
  #    new_info = Map.put(actor.info, "note_count", note_count)
  #
  #    cs = info_changeset(actor, %{info: new_info})
  #
  #    update_and_set_cache(cs)
  #  end

  @doc """
  Get an actor by it's URL (ActivityPub ID). The `:preload` option allows preloading the Followers relation.

  Raises `Ecto.NoResultsError` if the Actor does not exist.

  ## Examples
      iex> get_actor_by_url("https://mastodon.server.tld/users/user")
      {:ok, %Mobilizon.Actors.Actor{preferred_username: "user"}}

      iex> get_actor_by_url("https://mastodon.server.tld/users/user", true)
      {:ok, %Mobilizon.Actors.Actor{preferred_username: "user", followers: []}}

      iex> get_actor_by_url("non existent")
      {:error, :actor_not_found}

  """
  @spec get_actor_by_url(String.t(), boolean()) :: {:ok, Actor.t()} | {:error, :actor_not_found}
  def get_actor_by_url(url, preload \\ false) do
    case Repo.get_by(Actor, url: url) do
      nil ->
        {:error, :actor_not_found}

      actor ->
        actor = if preload, do: Repo.preload(actor, [:followers]), else: actor
        {:ok, actor}
    end
  end

  @doc """
  Get an actor by it's URL (ActivityPub ID). The `:preload` option allows preloading the Followers relation.

  Raises `Ecto.NoResultsError` if the Actor does not exist.

  ## Examples
      iex> get_actor_by_url!("https://mastodon.server.tld/users/user")
      %Mobilizon.Actors.Actor{}

      iex> get_actor_by_url!("https://mastodon.server.tld/users/user", true)
      {:ok, %Mobilizon.Actors.Actor{preferred_username: "user", followers: []}}

      iex> get_actor_by_url!("non existent")
      ** (Ecto.NoResultsError)

  """
  @spec get_actor_by_url!(String.t(), boolean()) :: struct()
  def get_actor_by_url!(url, preload \\ false) do
    actor = Repo.get_by!(Actor, url: url)
    if preload, do: Repo.preload(actor, [:followers]), else: actor
  end

  @doc """
  Get an actor by name

  ## Examples
      iex> get_actor_by_name("tcit")
      %Mobilizon.Actors.Actor{preferred_username: "tcit", domain: nil}

      iex> get_actor_by_name("tcit@social.tcit.fr")
      %Mobilizon.Actors.Actor{preferred_username: "tcit", domain: "social.tcit.fr"}

      iex> get_actor_by_name("tcit", :Group)
      nil

  """
  @spec get_actor_by_name(String.t(), atom() | nil) :: Actor.t()
  def get_actor_by_name(name, type \\ nil) do
    # Base query
    query = from(a in Actor)

    # If we have Person / Group information
    query =
      if type in [:Person, :Group] do
        from(a in query, where: a.type == ^type)
      else
        query
      end

    # If the name is a remote actor
    query =
      case String.split(name, "@") do
        [name] -> do_get_actor_by_name(query, name)
        [name, domain] -> do_get_actor_by_name(query, name, domain)
      end

    Repo.one(query)
  end

  # Get actor by username and domain is nil
  @spec do_get_actor_by_name(Ecto.Queryable.t(), String.t()) :: Ecto.Queryable.t()
  defp do_get_actor_by_name(query, name) do
    from(a in query, where: a.preferred_username == ^name and is_nil(a.domain))
  end

  # Get actor by username and domain
  @spec do_get_actor_by_name(Ecto.Queryable.t(), String.t(), String.t()) :: Ecto.Queryable.t()
  defp do_get_actor_by_name(query, name, domain) do
    from(a in query, where: a.preferred_username == ^name and a.domain == ^domain)
  end

  @doc """
  Return a local actor by it's preferred username
  """
  @spec get_local_actor_by_name(String.t()) :: Actor.t() | nil
  def get_local_actor_by_name(name) do
    Repo.one(
      from(a in Actor,
        where: a.preferred_username == ^name and is_nil(a.domain)
      )
    )
  end

  @doc """
  Return a local actor by it's preferred username and preload associations

  Preloads organized_events, followers and followings
  """
  @spec get_local_actor_by_name_with_everything(String.t()) :: Actor.t() | nil
  def get_local_actor_by_name_with_everything(name) do
    actor = Repo.one(from(a in Actor, where: a.preferred_username == ^name and is_nil(a.domain)))
    Repo.preload(actor, [:organized_events, :followers, :followings])
  end

  @doc """
  Returns actor by name and preloads the organized events

  ## Examples
      iex> get_actor_by_name_with_everything("tcit")
      %Mobilizon.Actors.Actor{preferred_username: "tcit", domain: nil, organized_events: []}

      iex> get_actor_by_name_with_everything("tcit@social.tcit.fr")
      %Mobilizon.Actors.Actor{preferred_username: "tcit", domain: "social.tcit.fr", organized_events: []}

      iex> get_actor_by_name_with_everything("tcit", :Group)
      nil

  """
  @spec get_actor_by_name_with_everything(String.t(), atom() | nil) :: Actor.t()
  def get_actor_by_name_with_everything(name, type \\ nil) do
    name
    |> get_actor_by_name(type)
    |> Repo.preload(:organized_events)
  end

  @doc """
  Returns a cached local actor by username
  """
  @spec get_cached_local_actor_by_name(String.t()) ::
          {:ok, Actor.t()} | {:commit, Actor.t()} | {:ignore, any()}
  def get_cached_local_actor_by_name(name) do
    Cachex.fetch(:activity_pub, "actor_" <> name, fn "actor_" <> name ->
      case get_local_actor_by_name(name) do
        nil -> {:ignore, nil}
        %Actor{} = actor -> {:commit, actor}
      end
    end)
  end

  @doc """
  Getting an actor from url, eventually creating it
  """
  # TODO: Move this to Mobilizon.Service.ActivityPub
  @spec get_or_fetch_by_url(String.t(), bool()) :: {:ok, Actor.t()} | {:error, String.t()}
  def get_or_fetch_by_url(url, preload \\ false) do
    case get_actor_by_url(url, preload) do
      {:ok, %Actor{} = actor} ->
        {:ok, actor}

      _ ->
        case ActivityPub.make_actor_from_url(url, preload) do
          {:ok, %Actor{} = actor} ->
            {:ok, actor}

          _ ->
            Logger.warn("Could not fetch by AP id")
            {:error, "Could not fetch by AP id"}
        end
    end
  end

  @doc """
  Getting an actor from url, eventually creating it

  Returns an error if fetch failed
  """
  # TODO: Move this to Mobilizon.Service.ActivityPub
  @spec get_or_fetch_by_url!(String.t(), bool()) :: Actor.t()
  def get_or_fetch_by_url!(url, preload \\ false) do
    case get_actor_by_url(url, preload) do
      {:ok, actor} ->
        actor

      _ ->
        case ActivityPub.make_actor_from_url(url, preload) do
          {:ok, actor} ->
            actor

          _ ->
            raise "Could not fetch by AP id"
        end
    end
  end

  @doc """
  Find local users by their username
  """
  # TODO: This doesn't seem to be used anyway
  @spec find_local_by_username(String.t()) :: list(Actor.t())
  def find_local_by_username(username) do
    actors =
      Repo.all(
        from(
          a in Actor,
          where:
            fragment(
              "f_unaccent(?) <% f_unaccent(?) or
             f_unaccent(coalesce(?, '')) <% f_unaccent(?)",
              a.preferred_username,
              ^username,
              a.name,
              ^username
            ),
          where: is_nil(a.domain),
          order_by:
            fragment(
              "word_similarity(?, ?) + word_similarity(coalesce(?, ''), ?) desc",
              a.preferred_username,
              ^username,
              a.name,
              ^username
            )
        )
      )

    Repo.preload(actors, :organized_events)
  end

  @doc """
  Find actors by their name or displayed name
  """
  @spec find_and_count_actors_by_username_or_name(
          String.t(),
          [ActorTypeEnum.t()],
          integer() | nil,
          integer() | nil
        ) ::
          %{total: integer(), elements: list(Actor.t())}
  def find_and_count_actors_by_username_or_name(username, _types, page \\ nil, limit \\ nil)

  def find_and_count_actors_by_username_or_name(username, types, page, limit) do
    query =
      from(
        a in Actor,
        where:
          fragment(
            "f_unaccent(?) %> f_unaccent(?) or
             f_unaccent(coalesce(?, '')) %> f_unaccent(?)",
            a.preferred_username,
            ^username,
            a.name,
            ^username
          ),
        where: a.type in ^types,
        order_by:
          fragment(
            "word_similarity(?, ?) + word_similarity(coalesce(?, ''), ?) desc",
            a.preferred_username,
            ^username,
            a.name,
            ^username
          )
      )
      |> Page.paginate(page, limit)

    total = Task.async(fn -> Repo.aggregate(query, :count, :id) end)
    elements = Task.async(fn -> Repo.all(query) end)

    %{total: Task.await(total), elements: Task.await(elements)}
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
  Create a new RSA key
  """
  @spec create_keys() :: String.t()
  def create_keys() do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)
    [entry] |> :public_key.pem_encode() |> String.trim_trailing()
  end

  @doc """
  Create a new person actor
  """
  @spec new_person(map()) :: {:ok, Actor.t()} | any
  def new_person(args) do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)
    pem = [entry] |> :public_key.pem_encode() |> String.trim_trailing()
    args = Map.put(args, :keys, pem)

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
        |> Actor.relay_creation()
        |> Repo.insert()
    end
  end

  alias Mobilizon.Actors.Member

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
  Returns an `%Ecto.Changeset{}` for tracking member changes.

  ## Examples

      iex> change_member(%Member{})
      %Ecto.Changeset{data: %Mobilizon.Actors.Member{}}

  """
  def change_member(%Member{} = member) do
    Member.changeset(member, %{})
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

  alias Mobilizon.Actors.Follower

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
  Returns an `%Ecto.Changeset{}` for tracking follower changes.

  ## Examples

      iex> change_follower(Follower{})
      %Ecto.Changeset{data: %Mobilizon.Actors.Follower{}}

  """
  def change_follower(%Follower{} = follower) do
    Follower.changeset(follower, %{})
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
end
