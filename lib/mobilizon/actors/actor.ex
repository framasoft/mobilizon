import EctoEnum

defenum(Mobilizon.Actors.ActorTypeEnum, :actor_type, [
  :Person,
  :Application,
  :Group,
  :Organization,
  :Service
])

defenum(Mobilizon.Actors.ActorOpennesssEnum, :openness, [
  :invite_only,
  :moderated,
  :open
])

defmodule Mobilizon.Actors.Actor do
  @moduledoc """
  Represents an actor (local and remote actors)
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, User, Follower, Member}
  alias Mobilizon.Events.Event

  import Ecto.Query
  import Mobilizon.Ecto
  alias Mobilizon.Repo

  require Logger

  #  @type t :: %Actor{description: String.t, id: integer(), inserted_at: DateTime.t, updated_at: DateTime.t, display_name: String.t, domain: String.t, keys: String.t, suspended: boolean(), url: String.t, username: String.t, organized_events: list(), groups: list(), group_request: list(), user: User.t, field: ActorTypeEnum.t}

  schema "actors" do
    field(:url, :string)
    field(:outbox_url, :string)
    field(:inbox_url, :string)
    field(:following_url, :string)
    field(:followers_url, :string)
    field(:shared_inbox_url, :string)
    field(:type, Mobilizon.Actors.ActorTypeEnum, default: :Person)
    field(:name, :string)
    field(:domain, :string)
    field(:summary, :string)
    field(:preferred_username, :string)
    field(:keys, :string)
    field(:manually_approves_followers, :boolean, default: false)
    field(:suspended, :boolean, default: false)
    field(:avatar_url, :string)
    field(:banner_url, :string)
    # field(:openness, Mobilizon.Actors.ActorOpennesssEnum, default: :moderated)
    has_many(:followers, Follower, foreign_key: :target_actor_id)
    has_many(:followings, Follower, foreign_key: :actor_id)
    has_many(:organized_events, Event, foreign_key: :organizer_actor_id)
    many_to_many(:memberships, Actor, join_through: Member)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(%Actor{} = actor, attrs) do
    actor
    |> Ecto.Changeset.cast(attrs, [
      :url,
      :outbox_url,
      :inbox_url,
      :shared_inbox_url,
      :following_url,
      :followers_url,
      :type,
      :name,
      :domain,
      :summary,
      :preferred_username,
      :keys,
      :manually_approves_followers,
      :suspended,
      :avatar_url,
      :banner_url,
      :user_id
    ])
    |> build_urls()
    |> validate_required([:preferred_username, :keys, :suspended, :url])
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
    |> unique_constraint(:url, name: :actors_url_index)
  end

  def registration_changeset(%Actor{} = actor, attrs) do
    actor
    |> Ecto.Changeset.cast(attrs, [
      :preferred_username,
      :domain,
      :name,
      :summary,
      :keys,
      :suspended,
      :url,
      :type,
      :avatar_url,
      :user_id
    ])
    |> build_urls()
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
    |> unique_constraint(:url, name: :actors_url_index)
    |> validate_required([:preferred_username, :keys, :suspended, :url, :type])
  end

  # TODO : Use me !
  # @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
  def remote_actor_creation(params) do
    changes =
      %Actor{}
      |> Ecto.Changeset.cast(params, [
        :url,
        :outbox_url,
        :inbox_url,
        :shared_inbox_url,
        :following_url,
        :followers_url,
        :type,
        :name,
        :domain,
        :summary,
        :preferred_username,
        :keys,
        :manually_approves_followers,
        :avatar_url,
        :banner_url
      ])
      |> validate_required([
        :url,
        :outbox_url,
        :inbox_url,
        :type,
        :domain,
        :preferred_username,
        :keys
      ])
      |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
      |> unique_constraint(:url, name: :actors_url_index)
      |> validate_length(:summary, max: 5000)
      |> validate_length(:preferred_username, max: 100)
      |> put_change(:local, false)

    Logger.debug("Remote actor creation")
    Logger.debug(inspect(changes))
    changes
  end

  def group_creation(%Actor{} = actor, params) do
    actor
    |> Ecto.Changeset.cast(params, [
      :url,
      :outbox_url,
      :inbox_url,
      :shared_inbox_url,
      :type,
      :name,
      :domain,
      :summary,
      :preferred_username,
      :avatar_url,
      :banner_url
    ])
    |> build_urls(:Group)
    |> put_change(:domain, nil)
    |> put_change(:keys, Actors.create_keys())
    |> put_change(:type, :Group)
    |> validate_required([:url, :outbox_url, :inbox_url, :type, :preferred_username])
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
    |> unique_constraint(:url, name: :actors_url_index)
    |> validate_length(:summary, max: 5000)
    |> validate_length(:preferred_username, max: 100)
    |> put_change(:local, true)
  end

  @spec build_urls(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  defp build_urls(changeset, type \\ :Person)

  defp build_urls(%Ecto.Changeset{changes: %{preferred_username: username}} = changeset, type) do
    symbol = if type == :Group, do: "~", else: "@"

    changeset
    |> put_change(
      :outbox_url,
      "#{MobilizonWeb.Endpoint.url()}/#{symbol}#{username}/outbox"
    )
    |> put_change(
      :inbox_url,
      "#{MobilizonWeb.Endpoint.url()}/#{symbol}#{username}/inbox"
    )
    |> put_change(:shared_inbox_url, "#{MobilizonWeb.Endpoint.url()}/inbox")
    |> put_change(:url, "#{MobilizonWeb.Endpoint.url()}/#{symbol}#{username}")
  end

  defp build_urls(%Ecto.Changeset{} = changeset, _type), do: changeset

  @doc """
  Get a public key for a given ActivityPub actor ID (url)
  """
  @spec get_public_key_for_url(String.t()) :: {:ok, String.t()}
  def get_public_key_for_url(url) do
    with {:ok, %Actor{keys: keys}} <- Actors.get_or_fetch_by_url(url),
         {:ok, public_key} <- prepare_public_key(keys) do
      {:ok, public_key}
    else
      {:error, :pem_decode_error} ->
        Logger.error("Error while decoding PEM")
        {:error, :pem_decode_error}

      _ ->
        Logger.error("Unable to fetch actor, so no keys for you")
        {:error, :actor_fetch_error}
    end
  end

  @doc """
  Convert internal PEM encoded keys to public key format
  """
  @spec prepare_public_key(String.t()) :: {:ok, tuple()} | {:error, :pem_decode_error}
  def prepare_public_key(public_key_code) do
    with [public_key_entry] <- :public_key.pem_decode(public_key_code) do
      {:ok, :public_key.pem_entry_decode(public_key_entry)}
    else
      _err ->
        {:error, :pem_decode_error}
    end
  end

  @doc """
  Get followers from an actor

  If actor A and C both follow actor B, actor B's followers are A and C
  """
  def get_followers(%Actor{id: actor_id} = _actor, page \\ nil, limit \\ nil) do
    Repo.all(
      from(
        a in Actor,
        join: f in Follower,
        on: a.id == f.actor_id,
        where: f.target_actor_id == ^actor_id
      )
      |> paginate(page, limit)
    )
  end

  @doc """
  Get followings from an actor

  If actor A follows actor B and C, actor A's followings are B and B
  """
  def get_followings(%Actor{id: actor_id} = _actor, page \\ nil, limit \\ nil) do
    Repo.all(
      from(
        a in Actor,
        join: f in Follower,
        on: a.id == f.target_actor_id,
        where: f.actor_id == ^actor_id
      )
      |> paginate(page, limit)
    )
  end

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

  @spec follow(struct(), struct(), boolean()) :: Follower.t() | {:error, String.t()}
  def follow(%Actor{} = followed, %Actor{} = follower, approved \\ true) do
    with {:suspended, false} <- {:suspended, followed.suspended},
         # Check if followed has blocked follower
         {:already_following, false} <- {:already_following, following?(follower, followed)} do
      do_follow(follower, followed, approved)
    else
      {:already_following, %Follower{}} ->
        {:error,
         "Could not follow actor: you are already following #{followed.preferred_username}"}

      {:suspended, _} ->
        {:error, "Could not follow actor: #{followed.preferred_username} has been suspended"}
    end
  end

  @spec unfollow(struct(), struct()) :: {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def unfollow(%Actor{} = followed, %Actor{} = follower) do
    with {:already_following, %Follower{} = follow} <-
           {:already_following, following?(follower, followed)} do
      Actors.delete_follower(follow)
    else
      {:already_following, false} ->
        {:error, "Could not unfollow actor: you are not following #{followed.preferred_username}"}
    end
  end

  defp do_follow(%Actor{} = follower, %Actor{} = followed, approved) do
    Actors.create_follower(%{
      "actor_id" => follower.id,
      "target_actor_id" => followed.id,
      "approved" => approved
    })
  end

  @spec following?(struct(), struct()) :: boolean()
  def following?(
        %Actor{} = follower_actor,
        %Actor{} = followed_actor
      ) do
    case Actors.get_follower(followed_actor, follower_actor) do
      nil -> false
      %Follower{} = follow -> follow
    end
  end

  @spec actor_acct_from_actor(struct()) :: String.t()
  def actor_acct_from_actor(%Actor{preferred_username: preferred_username, domain: domain}) do
    if is_nil(domain) do
      preferred_username
    else
      "#{preferred_username}@#{domain}"
    end
  end
end
