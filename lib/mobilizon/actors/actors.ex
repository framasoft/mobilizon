defmodule Mobilizon.Actors do
  @moduledoc """
  The Actors context.
  """

  import Ecto.Query
  import EctoEnum

  alias Ecto.Multi

  alias Mobilizon.Actors.{Actor, Bot, Follower, Member}
  alias Mobilizon.{Crypto, Events}
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

  @public_visibility [:public, :unlisted]
  @administrator_roles [:creator, :administrator]

  @doc """
  Gets a single actor.
  """
  @spec get_actor(integer | String.t()) :: Actor.t() | nil
  def get_actor(id), do: Repo.get(Actor, id)

  @doc """
  Gets a single actor.
  Raises `Ecto.NoResultsError` if the actor does not exist.
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
  Creates an actor.
  """
  @spec create_actor(map) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def create_actor(attrs \\ %{}) do
    %Actor{}
    |> Actor.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a new person actor.
  """
  @spec new_person(map) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def new_person(args) do
    args = Map.put(args, :keys, Crypto.generate_rsa_2048_private_key())

    with {:ok, %Actor{} = person} <-
           %Actor{}
           |> Actor.registration_changeset(args)
           |> Repo.insert() do
      Events.create_feed_token(%{"user_id" => args["user_id"], "actor_id" => person.id})

      {:ok, person}
    end
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
  Returns the list of local actors by their username.
  """
  @spec list_local_actor_by_username(String.t()) :: [Actor.t()]
  def list_local_actor_by_username(username) do
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

  @doc """
  Gets a group by its actor id.
  """
  @spec get_group_by_actor_id(integer | String.t()) ::
          {:ok, Actor.t()} | {:error, :group_not_found}
  def get_group_by_actor_id(actor_id) do
    case Repo.get_by(Actor, id: actor_id, type: :Group) do
      nil ->
        {:error, :group_not_found}

      actor ->
        {:ok, actor}
    end
  end

  @doc """
  Creates a group.
  """
  @spec create_group(map) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def create_group(attrs \\ %{}) do
    %Actor{}
    |> Actor.group_creation_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a group.
  """
  def delete_group!(%Actor{type: :Group} = group), do: Repo.delete!(group)

  @doc """
  Lists the groups.
  """
  @spec list_groups(integer | nil, integer | nil) :: [Actor.t()]
  def list_groups(page \\ nil, limit \\ nil) do
    groups_query()
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

  @doc """
  Returns the list of groups an actor is member of.
  """
  @spec list_groups_member_of(Actor.t()) :: [Actor.t()]
  def list_groups_member_of(%Actor{id: actor_id}) do
    actor_id
    |> groups_member_of_query()
    |> Repo.all()
  end

  @doc """
  Gets a single member.
  Raises `Ecto.NoResultsError` if the member does not exist.
  """
  @spec get_member!(integer | String.t()) :: Member.t()
  def get_member!(id), do: Repo.get!(Member, id)

  @doc """
  Gets a single member of an actor (for example a group).
  """
  @spec get_member(integer | String.t(), integer | String.t()) ::
          {:ok, Member.t()} | {:error, :member_not_found}
  def get_member(actor_id, parent_id) do
    case Repo.get_by(Member, actor_id: actor_id, parent_id: parent_id) do
      nil ->
        {:error, :member_not_found}

      member ->
        {:ok, member}
    end
  end

  @doc """
  Creates a member.
  """
  @spec create_member(map) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
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
  """
  @spec update_member(Member.t(), map) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
  def update_member(%Member{} = member, attrs) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a member.
  """
  @spec delete_member(Member.t()) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
  def delete_member(%Member{} = member), do: Repo.delete(member)

  @doc """
  Returns the list of members for an actor.
  """
  @spec list_members_for_actor(Actor.t()) :: [Member.t()]
  def list_members_for_actor(%Actor{id: actor_id}) do
    actor_id
    |> members_for_actor_query()
    |> Repo.all()
  end

  @doc """
  Returns the list of members for a group.
  """
  @spec list_members_for_group(Actor.t()) :: [Member.t()]
  def list_members_for_group(%Actor{id: group_id, type: :Group}) do
    group_id
    |> members_for_group_query()
    |> Repo.all()
  end

  @doc """
  Returns the list of administrator members for a group.
  """
  @spec list_administrator_members_for_group(integer | String.t(), integer | nil, integer | nil) ::
          [Member.t()]
  def list_administrator_members_for_group(id, page \\ nil, limit \\ nil) do
    id
    |> administrator_members_for_group_query()
    |> Page.paginate(page, limit)
    |> Repo.all()
  end

  @doc """
  Returns the list of all group ids where the actor_id is the last administrator.
  """
  @spec list_group_ids_where_last_administrator(integer | String.t()) :: [integer]
  def list_group_ids_where_last_administrator(actor_id) do
    actor_id
    |> group_ids_where_last_administrator_query()
    |> Repo.all()
  end

  @doc """
  Gets a single bot.
  Raises `Ecto.NoResultsError` if the bot does not exist.
  """
  def get_bot!(id), do: Repo.get!(Bot, id)

  @doc """
  Gets the bot associated to an actor.
  """
  @spec get_bot_for_actor(Actor.t()) :: Bot.t()
  def get_bot_for_actor(%Actor{id: actor_id}) do
    Repo.get_by!(Bot, actor_id: actor_id)
  end

  @doc """
  Creates a bot.
  """
  @spec create_bot(map) :: {:ok, Bot.t()} | {:error, Ecto.Changeset.t()}
  def create_bot(attrs \\ %{}) do
    %Bot{}
    |> Bot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Registers a new bot.
  """
  @spec register_bot(map) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def register_bot(%{name: name, summary: summary}) do
    attrs = %{
      preferred_username: name,
      domain: nil,
      keys: Crypto.generate_rsa_2048_private_key(),
      summary: summary,
      type: :Service
    }

    %Actor{}
    |> Actor.registration_changeset(attrs)
    |> Repo.insert()
  end

  @spec get_or_create_actor_by_url(String.t(), String.t()) ::
          {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_actor_by_url(url, preferred_username \\ "relay") do
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
  Updates a bot.
  """
  @spec update_bot(Bot.t(), map) :: {:ok, Bot.t()} | {:error, Ecto.Changeset.t()}
  def update_bot(%Bot{} = bot, attrs) do
    bot
    |> Bot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bot.
  """
  @spec delete_bot(Bot.t()) :: {:ok, Bot.t()} | {:error, Ecto.Changeset.t()}
  def delete_bot(%Bot{} = bot), do: Repo.delete(bot)

  @doc """
  Returns the list of bots.
  """
  @spec list_bots :: [Bot.t()]
  def list_bots, do: Repo.all(Bot)

  @doc """
  Gets a single follower.
  Raises `Ecto.NoResultsError` if the follower does not exist.
  """
  @spec get_follower!(integer | String.t()) :: Follower.t()
  def get_follower!(id) do
    Follower
    |> Repo.get!(id)
    |> Repo.preload([:actor, :target_actor])
  end

  @doc """
  Get a follower by the url.
  """
  @spec get_follower_by_url(String.t()) :: Follower.t()
  def get_follower_by_url(url) do
    url
    |> follower_by_url()
    |> Repo.one()
  end

  @doc """
  Gets a follower by the followed actor and following actor
  """
  @spec get_follower_by_followed_and_following(Actor.t(), Actor.t()) :: Follower.t() | nil
  def get_follower_by_followed_and_following(%Actor{id: followed_id}, %Actor{id: following_id}) do
    followed_id
    |> follower_by_followed_and_following_query(following_id)
    |> Repo.one()
  end

  @doc """
  Creates a follower.
  """
  @spec create_follower(map) :: {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
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
  """
  @spec update_follower(Follower.t(), map) :: {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def update_follower(%Follower{} = follower, attrs) do
    follower
    |> Follower.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a follower.
  """
  @spec delete_follower(Follower.t()) :: {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def delete_follower(%Follower{} = follower), do: Repo.delete(follower)

  @doc """
  Deletes a follower by followed and following actors.
  """
  @spec delete_follower_by_followed_and_following(Actor.t(), Actor.t()) ::
          {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def delete_follower_by_followed_and_following(%Actor{} = followed, %Actor{} = following) do
    followed
    |> get_follower_by_followed_and_following(following)
    |> Repo.delete()
  end

  @doc """
  Returns the list of followers for an actor.
  If actor A and C both follow actor B, actor B's followers are A and C.
  """
  @spec list_followers_for_actor(Actor.t()) :: [Follower.t()]
  def list_followers_for_actor(%Actor{id: actor_id}) do
    actor_id
    |> followers_for_actor_query()
    |> Repo.all()
  end

  @doc """
  Returns the list of external followers for an actor.
  """
  @spec list_external_followers_for_actor(Actor.t()) :: [Follower.t()]
  def list_external_followers_for_actor(%Actor{id: actor_id}) do
    actor_id
    |> followers_for_actor_query()
    |> filter_external()
    |> Repo.all()
  end

  @doc """
  Build a page struct for followers of an actor.
  """
  @spec build_followers_for_actor(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def build_followers_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> followers_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of followings for an actor.
  If actor A follows actor B and C, actor A's followings are B and C.
  """
  @spec list_followings_for_actor(Actor.t()) :: [Follower.t()]
  def list_followings_for_actor(%Actor{id: actor_id}) do
    actor_id
    |> followings_for_actor_query()
    |> Repo.all()
  end

  @doc """
  Build a page struct for followings of an actor.
  """
  @spec build_followings_for_actor(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def build_followings_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> followings_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Makes an actor following another actor.
  """
  @spec follow(Actor.t(), Actor.t(), String.t() | nil, boolean | nil) ::
          {:ok, Follower.t()} | {:error, atom, String.t()}
  def follow(%Actor{} = followed, %Actor{} = follower, url \\ nil, approved \\ true) do
    with {:suspended, false} <- {:suspended, followed.suspended},
         # Check if followed has blocked follower
         {:already_following, nil} <- {:already_following, is_following(follower, followed)} do
      Logger.info(
        "Making #{follower.preferred_username} follow #{followed.preferred_username} " <>
          "(approved: #{approved})"
      )

      create_follower(%{
        "actor_id" => follower.id,
        "target_actor_id" => followed.id,
        "approved" => approved,
        "url" => url
      })
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
  Unfollows an actor (removes a Follower record).
  """
  @spec unfollow(Actor.t(), Actor.t()) ::
          {:ok, Follower.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def unfollow(%Actor{} = followed, %Actor{} = follower) do
    case {:already_following, is_following(follower, followed)} do
      {:already_following, %Follower{} = follow} ->
        delete_follower(follow)

      {:already_following, nil} ->
        {:error, "Could not unfollow actor: you are not following #{followed.preferred_username}"}
    end
  end

  @doc """
  Checks whether an actor is following another actor.
  """
  @spec is_following(Actor.t(), Actor.t()) :: Follower.t() | nil
  def is_following(%Actor{} = follower_actor, %Actor{} = followed_actor) do
    get_follower_by_followed_and_following(followed_actor, follower_actor)
  end

  @spec remove_banner(Actor.t()) :: {:ok, Actor.t()}
  defp remove_banner(%Actor{banner: nil} = actor), do: {:ok, actor}

  defp remove_banner(%Actor{banner: %File{url: url}} = actor) do
    safe_remove_file(url, actor)
  end

  @spec remove_avatar(Actor.t()) :: {:ok, Actor.t()}
  defp remove_avatar(%Actor{avatar: nil} = actor), do: {:ok, actor}

  defp remove_avatar(%Actor{avatar: %File{url: url}} = actor) do
    safe_remove_file(url, actor)
  end

  @spec safe_remove_file(String.t(), Actor.t()) :: {:ok, Actor.t()}
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

  @spec actor_with_preload_query(integer | String.t()) :: Ecto.Query.t()
  defp actor_with_preload_query(actor_id) do
    from(
      a in Actor,
      where: a.id == ^actor_id,
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
    from(a in Actor, where: a.type == ^:Group)
  end

  @spec groups_member_of_query(integer | String.t()) :: Ecto.Query.t()
  defp groups_member_of_query(actor_id) do
    from(
      a in Actor,
      join: m in Member,
      on: a.id == m.parent_id,
      where: m.actor_id == ^actor_id
    )
  end

  @spec groups_query :: Ecto.Query.t()
  defp groups_query do
    from(
      a in Actor,
      where: a.type == ^:Group,
      where: a.visibility in ^@public_visibility
    )
  end

  @spec members_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp members_for_actor_query(actor_id) do
    from(
      m in Member,
      where: m.actor_id == ^actor_id,
      preload: [:parent]
    )
  end

  @spec members_for_group_query(integer | String.t()) :: Ecto.Query.t()
  defp members_for_group_query(group_id) do
    from(
      m in Member,
      where: m.parent_id == ^group_id,
      preload: [:parent, :actor]
    )
  end

  @spec administrator_members_for_group_query(integer | String.t()) :: Ecto.Query.t()
  defp administrator_members_for_group_query(group_id) do
    from(
      m in Member,
      where: m.parent_id == ^group_id and m.role in ^@administrator_roles,
      preload: [:actor]
    )
  end

  @spec administrator_members_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp administrator_members_for_actor_query(actor_id) do
    from(
      m in Member,
      where: m.actor_id == ^actor_id and m.role in ^@administrator_roles,
      select: m.parent_id
    )
  end

  @spec group_ids_where_last_administrator_query(integer | String.t()) :: Ecto.Query.t()
  defp group_ids_where_last_administrator_query(actor_id) do
    from(
      m in Member,
      where: m.role in ^@administrator_roles,
      join: m2 in subquery(administrator_members_for_actor_query(actor_id)),
      on: m.parent_id == m2.parent_id,
      group_by: m.parent_id,
      select: m.parent_id,
      having: count(m.actor_id) == 1
    )
  end

  @spec follower_by_url(String.t()) :: Ecto.Query.t()
  defp follower_by_url(url) do
    from(
      f in Follower,
      where: f.url == ^url,
      preload: [:actor, :target_actor]
    )
  end

  @spec follower_by_followed_and_following_query(integer | String.t(), integer | String.t()) ::
          Ecto.Query.t()
  defp follower_by_followed_and_following_query(followed_id, follower_id) do
    from(
      f in Follower,
      where: f.target_actor_id == ^followed_id and f.actor_id == ^follower_id
    )
  end

  @spec followers_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp followers_for_actor_query(actor_id) do
    from(
      a in Actor,
      join: f in Follower,
      on: a.id == f.actor_id,
      where: f.target_actor_id == ^actor_id
    )
  end

  @spec followings_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp followings_for_actor_query(actor_id) do
    from(
      a in Actor,
      join: f in Follower,
      on: a.id == f.target_actor_id,
      where: f.actor_id == ^actor_id
    )
  end

  @spec filter_local(Ecto.Query.t()) :: Ecto.Query.t()
  defp filter_local(query) do
    from(a in query, where: is_nil(a.domain))
  end

  @spec filter_external(Ecto.Query.t()) :: Ecto.Query.t()
  defp filter_external(query) do
    from(a in query, where: not is_nil(a.domain))
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
end
