import EctoEnum

defenum(Mobilizon.Actors.ActorTypeEnum, :actor_type, [
  :Person,
  :Application,
  :Group,
  :Organization,
  :Service
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
  alias Mobilizon.Service.ActivityPub

  import Ecto.Query
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
    many_to_many(:followers, Actor, join_through: Follower)
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
    |> put_change(:url, "#{MobilizonWeb.Endpoint.url()}/@#{attrs["preferred_username"]}")
    |> validate_required([:preferred_username, :keys, :suspended, :url])
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_index)
  end

  def registration_changeset(%Actor{} = actor, attrs) do
    actor
    |> Ecto.Changeset.cast(attrs, [
      :preferred_username,
      :domain,
      :name,
      :summary,
      :keys,
      :keys,
      :suspended,
      :url,
      :type,
      :avatar_url,
      :user_id
    ])
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_index)
    |> put_change(:url, "#{MobilizonWeb.Endpoint.url()}/@#{attrs.preferred_username}")
    |> put_change(:inbox_url, "#{MobilizonWeb.Endpoint.url()}/@#{attrs.preferred_username}/inbox")
    |> put_change(
      :outbox_url,
      "#{MobilizonWeb.Endpoint.url()}/@#{attrs.preferred_username}/outbox"
    )
    |> put_change(:shared_inbox_url, "#{MobilizonWeb.Endpoint.url()}/inbox")
    |> validate_required([:preferred_username, :keys, :suspended, :url, :type])
  end

  # TODO : Use me !
  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
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
        :name,
        :domain,
        :preferred_username,
        :keys
      ])
      |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_index)
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
    |> put_change(
      :outbox_url,
      "#{MobilizonWeb.Endpoint.url()}/@#{params["preferred_username"]}/outbox"
    )
    |> put_change(
      :inbox_url,
      "#{MobilizonWeb.Endpoint.url()}/@#{params["preferred_username"]}/inbox"
    )
    |> put_change(:shared_inbox_url, "#{MobilizonWeb.Endpoint.url()}/inbox")
    |> put_change(:url, "#{MobilizonWeb.Endpoint.url()}/@#{params["preferred_username"]}")
    |> put_change(:domain, nil)
    |> put_change(:type, :Group)
    |> validate_required([:url, :outbox_url, :inbox_url, :type, :name, :preferred_username])
    |> validate_length(:summary, max: 5000)
    |> validate_length(:preferred_username, max: 100)
    |> put_change(:local, true)
  end

  @spec get_public_key_for_url(String.t()) :: {:ok, String.t()}
  def get_public_key_for_url(url) do
    with {:ok, %Actor{} = actor} <- Actors.get_or_fetch_by_url(url) do
      {:ok, actor.keys}
    else
      _ ->
        Logger.error("Unable to fetch actor, so no keys for you")
        {:error, :actor_fetch_error}
    end
  end

  @doc """
  Get followers from an actor

  If actor A and C both follow actor B, actor B's followers are A and C
  """
  def get_followers(%Actor{id: actor_id} = _actor) do
    Repo.all(
      from(
        a in Actor,
        join: f in Follower,
        on: a.id == f.actor_id,
        where: f.target_actor_id == ^actor_id
      )
    )
  end

  @doc """
  Get followings from an actor

  If actor A follows actor B and C, actor A's followings are B and B
  """
  def get_followings(%Actor{id: actor_id} = _actor) do
    Repo.all(
      from(
        a in Actor,
        join: f in Follower,
        on: a.id == f.target_actor_id,
        where: f.actor_id == ^actor_id
      )
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

  def follow(%Actor{} = follower, %Actor{} = followed) do
    # Check if actor is locked
    # Check if followed has blocked follower
    # Check if follower already follows followed
    cond do
      following?(follower, followed) ->
        {:error,
         "Could not follow actor: you are already following #{followed.preferred_username}"}

        # true -> nil
        # Follow the person
    end
  end

  def following?(%Actor{} = follower, %Actor{followers: followers}) do
    Enum.member?(followers, follower)
  end
end
