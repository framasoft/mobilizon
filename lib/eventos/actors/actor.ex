defmodule Eventos.Actors.Actor.TitleSlug do
  @moduledoc """
  Slug generation for groups
  """
  alias Eventos.Actors.Actor
  import Ecto.Query
  alias Eventos.Repo
  use EctoAutoslugField.Slug, from: :title, to: :slug

  def build_slug(sources, changeset) do
    slug = super(sources, changeset)
    build_unique_slug(slug, changeset)
  end

  defp build_unique_slug(slug, changeset) do
    query = from a in Actor,
                 where: a.slug == ^slug

    case Repo.one(query) do
      nil -> slug
      _story ->
        slug
        |> Eventos.Slug.increment_slug()
        |> build_unique_slug(changeset)
    end
  end
end

import EctoEnum
defenum Eventos.Actors.ActorTypeEnum, :actor_type, [:Person, :Application, :Group, :Organization, :Service]


defmodule Eventos.Actors.Actor do
  @moduledoc """
  Represents an actor (local and remote actors)
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Actors
  alias Eventos.Actors.{Actor, User, Follower, Member}
  alias Eventos.Events.Event
  alias Eventos.Service.ActivityPub

  import Ecto.Query
  alias Eventos.Repo

  import Logger

#  @type t :: %Actor{description: String.t, id: integer(), inserted_at: DateTime.t, updated_at: DateTime.t, display_name: String.t, domain: String.t, keys: String.t, suspended: boolean(), url: String.t, username: String.t, organized_events: list(), groups: list(), group_request: list(), user: User.t, field: ActorTypeEnum.t}

  schema "actors" do
    field :url, :string
    field :outbox_url, :string
    field :inbox_url, :string
    field :following_url, :string
    field :followers_url, :string
    field :shared_inbox_url, :string
    field :type, Eventos.Actors.ActorTypeEnum, default: :Person
    field :name, :string
    field :domain, :string
    field :summary, :string
    field :preferred_username, :string
    field :keys, :string
    field :manually_approves_followers, :boolean, default: false
    field :suspended, :boolean, default: false
    field :avatar_url, :string
    field :banner_url, :string
    many_to_many :followers, Actor, join_through: Follower
    has_many :organized_events, Event, [foreign_key: :organizer_actor_id]
    many_to_many :memberships, Actor, join_through: Member
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(%Actor{} = actor, attrs) do
    actor
    |> Ecto.Changeset.cast(attrs, [:url, :outbox_url, :inbox_url, :shared_inbox_url, :following_url, :followers_url, :type, :name, :domain, :summary, :preferred_username, :keys, :manually_approves_followers, :suspended, :avatar_url, :banner_url, :user_id])
    |> put_change(:url, "#{EventosWeb.Endpoint.url()}/@#{attrs["prefered_username"]}")
    |> validate_required([:preferred_username, :keys, :suspended, :url])
    |> unique_constraint(:prefered_username, name: :actors_preferred_username_domain_index)
  end

  def registration_changeset(%Actor{} = actor, attrs) do
    actor
    |> Ecto.Changeset.cast(attrs, [:preferred_username, :domain, :name, :summary, :keys, :keys, :suspended, :url, :type, :avatar_url, :user_id])
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_index)
    |> put_change(:url, "#{EventosWeb.Endpoint.url()}/@#{attrs["prefered_username"]}")
    |> validate_required([:preferred_username, :keys, :suspended, :url, :type])
  end

  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
  def remote_actor_creation(params) do
    changes =
      %Actor{}
      |> Ecto.Changeset.cast(params, [:url, :outbox_url, :inbox_url, :shared_inbox_url, :following_url, :followers_url, :type, :name, :domain, :summary, :preferred_username, :keys, :manually_approves_followers, :avatar_url, :banner_url])
      |> validate_required([:url, :outbox_url, :inbox_url, :type, :name, :domain, :preferred_username, :keys])
      |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_index)
      |> validate_length(:summary, max: 5000)
      |> validate_length(:preferred_username, max: 100)
      |> put_change(:local, false)

    Logger.debug("Remote actor creation")
    Logger.debug(inspect changes)
    changes
  end

  def group_creation(%Actor{} = actor, params) do
    actor
    |> Ecto.Changeset.cast(params, [:url, :outbox_url, :inbox_url, :shared_inbox_url, :type, :name, :domain, :summary, :preferred_username, :avatar_url, :banner_url])
    |> put_change(:outbox_url, "#{EventosWeb.Endpoint.url()}/@#{params["prefered_username"]}/outbox")
    |> put_change(:inbox_url, "#{EventosWeb.Endpoint.url()}/@#{params["prefered_username"]}/inbox")
    |> put_change(:shared_inbox_url, "#{EventosWeb.Endpoint.url()}/inbox")
    |> put_change(:url, "#{EventosWeb.Endpoint.url()}/@#{params["prefered_username"]}")
    |> put_change(:domain, nil)
    |> put_change(:type, "Group")
    |> validate_required([:url, :outbox_url, :inbox_url, :type, :name, :preferred_username])
    |> validate_length(:summary, max: 5000)
    |> validate_length(:preferred_username, max: 100)
    |> put_change(:local, true)
  end

  def get_or_fetch_by_url(url) do
    if user = Actors.get_actor_by_url(url) do
      user
    else
      case ActivityPub.make_actor_from_url(url) do
        {:ok, user} ->
          user
        _ -> {:error, "Could not fetch by AP id"}
      end
    end
  end

  #@spec get_public_key_for_url(Actor.t) :: {:ok, String.t}
  def get_public_key_for_url(url) do
    with %Actor{} = actor <- get_or_fetch_by_url(url) do
      actor
      |> get_keys_for_actor
      |> Eventos.Service.ActivityPub.Utils.pem_to_public_key
    else
      _ -> :error
    end
  end

  @deprecated "Use get_keys_for_actor/1 instead"
  #@spec get_public_key_for_actor(Actor.t) :: {:ok, String.t}
  def get_public_key_for_actor(%Actor{} = actor) do
    {:ok, actor.keys}
  end

  @doc """
  Returns a pem encoded keypair (if local) or public key
  """
  def get_keys_for_actor(%Actor{} = actor) do
    actor.keys
  end

  @deprecated "Use get_keys_for_actor/1 instead"
  #@spec get_private_key_for_actor(Actor.t) :: {:ok, String.t}
  def get_private_key_for_actor(%Actor{} = actor) do
    actor.keys
  end

  def get_followers(%Actor{id: actor_id} = actor) do
    Repo.all(
      from a in Actor,
      join: f in Follower, on: a.id == f.actor_id,
      where: f.target_actor_id == ^actor_id
    )
  end

  def get_followings(%Actor{id: actor_id} = actor) do
    Repo.all(
      from a in Actor,
      join: f in Follower, on: a.id == f.target_actor_id,
      where: f.actor_id == ^actor_id
    )
  end
end
