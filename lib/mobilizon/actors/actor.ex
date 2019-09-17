defmodule Mobilizon.Actors.Actor do
  @moduledoc """
  Represents an actor (local and remote).
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.{Actors, Config, Crypto}
  alias Mobilizon.Actors.{ActorOpenness, ActorType, ActorVisibility, Follower, Member}
  alias Mobilizon.Events.{Event, FeedToken}
  alias Mobilizon.Media.File
  alias Mobilizon.Reports.{Report, Note}
  alias Mobilizon.Users.User

  alias MobilizonWeb.Router.Helpers, as: Routes
  alias MobilizonWeb.Endpoint

  require Logger

  @type t :: %__MODULE__{
          url: String.t(),
          outbox_url: String.t(),
          inbox_url: String.t(),
          following_url: String.t(),
          followers_url: String.t(),
          shared_inbox_url: String.t(),
          type: ActorType.t(),
          name: String.t(),
          domain: String.t(),
          summary: String.t(),
          preferred_username: String.t(),
          keys: String.t(),
          manually_approves_followers: boolean,
          openness: ActorOpenness.t(),
          visibility: ActorVisibility.t(),
          suspended: boolean,
          avatar: File.t(),
          banner: File.t(),
          user: User.t(),
          followers: [Follower.t()],
          followings: [Follower.t()],
          organized_events: [Event.t()],
          feed_tokens: [FeedToken.t()],
          created_reports: [Report.t()],
          subject_reports: [Report.t()],
          report_notes: [Note.t()],
          memberships: [t]
        }

  @required_attrs [:preferred_username, :keys, :suspended, :url]
  @optional_attrs [
    :outbox_url,
    :inbox_url,
    :shared_inbox_url,
    :following_url,
    :followers_url,
    :type,
    :name,
    :domain,
    :summary,
    :manually_approves_followers,
    :user_id
  ]
  @attrs @required_attrs ++ @optional_attrs

  @update_required_attrs @required_attrs -- [:url]
  @update_optional_attrs [:name, :summary, :manually_approves_followers, :user_id]
  @update_attrs @update_required_attrs ++ @update_optional_attrs

  @registration_required_attrs [:preferred_username, :keys, :suspended, :url, :type]
  @registration_optional_attrs [:domain, :name, :summary, :user_id]
  @registration_attrs @registration_required_attrs ++ @registration_optional_attrs

  @remote_actor_creation_required_attrs [
    :url,
    :inbox_url,
    :type,
    :domain,
    :preferred_username,
    :keys
  ]
  @remote_actor_creation_optional_attrs [
    :outbox_url,
    :shared_inbox_url,
    :following_url,
    :followers_url,
    :name,
    :summary,
    :manually_approves_followers
  ]
  @remote_actor_creation_attrs @remote_actor_creation_required_attrs ++
                                 @remote_actor_creation_optional_attrs

  @relay_creation_attrs [
    :type,
    :name,
    :summary,
    :url,
    :keys,
    :preferred_username,
    :domain,
    :inbox_url,
    :followers_url,
    :following_url,
    :shared_inbox_url
  ]

  @group_creation_required_attrs [:url, :outbox_url, :inbox_url, :type, :preferred_username]
  @group_creation_optional_attrs [:shared_inbox_url, :name, :domain, :summary]
  @group_creation_attrs @group_creation_required_attrs ++ @group_creation_optional_attrs

  schema "actors" do
    field(:url, :string)
    field(:outbox_url, :string)
    field(:inbox_url, :string)
    field(:following_url, :string)
    field(:followers_url, :string)
    field(:shared_inbox_url, :string)
    field(:type, ActorType, default: :Person)
    field(:name, :string)
    field(:domain, :string, default: nil)
    field(:summary, :string)
    field(:preferred_username, :string)
    field(:keys, :string)
    field(:manually_approves_followers, :boolean, default: false)
    field(:openness, ActorOpenness, default: :moderated)
    field(:visibility, ActorVisibility, default: :private)
    field(:suspended, :boolean, default: false)

    embeds_one(:avatar, File, on_replace: :update)
    embeds_one(:banner, File, on_replace: :update)
    belongs_to(:user, User)
    has_many(:followers, Follower, foreign_key: :target_actor_id)
    has_many(:followings, Follower, foreign_key: :actor_id)
    has_many(:organized_events, Event, foreign_key: :organizer_actor_id)
    has_many(:feed_tokens, FeedToken, foreign_key: :actor_id)
    has_many(:created_reports, Report, foreign_key: :reporter_id)
    has_many(:subject_reports, Report, foreign_key: :reported_id)
    has_many(:report_notes, Note, foreign_key: :moderator_id)
    many_to_many(:memberships, __MODULE__, join_through: Member)

    timestamps()
  end

  @doc """
  Checks whether actor visibility is public.
  """
  @spec is_public_visibility(t) :: boolean
  def is_public_visibility(%__MODULE__{visibility: visibility}) do
    visibility in [:public, :unlisted]
  end

  @doc """
  Returns the display name if available, or the preferred username
  (with the eventual @domain suffix if it's a distant actor).
  """
  @spec display_name(t) :: String.t()
  def display_name(%__MODULE__{name: name} = actor) when name in [nil, ""] do
    preferred_username_and_domain(actor)
  end

  def display_name(%__MODULE__{name: name}), do: name

  @doc """
  Returns display name and username.
  """
  @spec display_name_and_username(t) :: String.t()
  def display_name_and_username(%__MODULE__{name: name} = actor) when name in [nil, ""] do
    preferred_username_and_domain(actor)
  end

  def display_name_and_username(%__MODULE__{name: name} = actor) do
    "#{name} (#{preferred_username_and_domain(actor)})"
  end

  @doc """
  Returns the preferred username with the eventual @domain suffix if it's
  a distant actor.
  """
  @spec preferred_username_and_domain(t) :: String.t()
  def preferred_username_and_domain(%__MODULE__{
        preferred_username: preferred_username,
        domain: nil
      }) do
    preferred_username
  end

  def preferred_username_and_domain(%__MODULE__{
        preferred_username: preferred_username,
        domain: domain
      }) do
    "#{preferred_username}@#{domain}"
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = actor, attrs) do
    actor
    |> cast(attrs, @attrs)
    |> build_urls()
    |> cast_embed(:avatar)
    |> cast_embed(:banner)
    |> unique_username_validator()
    |> validate_required(@required_attrs)
    |> unique_constraint(:preferred_username,
      name: :actors_preferred_username_domain_type_index
    )
    |> unique_constraint(:url, name: :actors_url_index)
  end

  @doc false
  @spec update_changeset(t, map) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = actor, attrs) do
    actor
    |> cast(attrs, @update_attrs)
    |> cast_embed(:avatar)
    |> cast_embed(:banner)
    |> validate_required(@update_required_attrs)
    |> unique_constraint(:preferred_username,
      name: :actors_preferred_username_domain_type_index
    )
    |> unique_constraint(:url, name: :actors_url_index)
  end

  @doc """
  Changeset for person registration.
  """
  @spec registration_changeset(t, map) :: Ecto.Changeset.t()
  def registration_changeset(%__MODULE__{} = actor, attrs) do
    actor
    |> cast(attrs, @registration_attrs)
    |> build_urls()
    |> cast_embed(:avatar)
    |> cast_embed(:banner)
    |> unique_username_validator()
    |> unique_constraint(:preferred_username,
      name: :actors_preferred_username_domain_type_index
    )
    |> unique_constraint(:url, name: :actors_url_index)
    |> validate_required(@registration_required_attrs)
  end

  @doc """
  Changeset for remote actor creation.
  """
  @spec remote_actor_creation_changeset(map) :: Ecto.Changeset.t()
  def remote_actor_creation_changeset(attrs) do
    changeset =
      %__MODULE__{}
      |> cast(attrs, @remote_actor_creation_attrs)
      |> validate_required(@remote_actor_creation_required_attrs)
      |> cast_embed(:avatar)
      |> cast_embed(:banner)
      |> unique_username_validator()
      |> unique_constraint(:preferred_username,
        name: :actors_preferred_username_domain_type_index
      )
      |> unique_constraint(:url, name: :actors_url_index)
      |> validate_length(:summary, max: 5000)
      |> validate_length(:preferred_username, max: 100)

    Logger.debug("Remote actor creation: #{inspect(changeset)}")

    changeset
  end

  @doc """
  Changeset for relay creation.
  """
  @spec relay_creation_changeset(map) :: Ecto.Changeset.t()
  def relay_creation_changeset(attrs) do
    relay_creation_attrs = build_relay_creation_attrs(attrs)

    cast(%__MODULE__{}, relay_creation_attrs, @relay_creation_attrs)
  end

  @doc """
  Changeset for group creation
  """
  @spec group_creation_changeset(t, map) :: Ecto.Changeset.t()
  def group_creation_changeset(%__MODULE__{} = actor, params) do
    actor
    |> cast(params, @group_creation_attrs)
    |> cast_embed(:avatar)
    |> cast_embed(:banner)
    |> build_urls(:Group)
    |> put_change(:domain, nil)
    |> put_change(:keys, Crypto.generate_rsa_2048_private_key())
    |> put_change(:type, :Group)
    |> unique_username_validator()
    |> validate_required(@group_creation_required_attrs)
    |> unique_constraint(:preferred_username,
      name: :actors_preferred_username_domain_type_index
    )
    |> unique_constraint(:url, name: :actors_url_index)
    |> validate_length(:summary, max: 5000)
    |> validate_length(:preferred_username, max: 100)
  end

  # Needed because following constraint can't work for domain null values (local)
  @spec unique_username_validator(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp unique_username_validator(
         %Ecto.Changeset{changes: %{preferred_username: username} = changes} = changeset
       ) do
    with nil <- Map.get(changes, :domain, nil),
         %__MODULE__{preferred_username: _} <- Actors.get_local_actor_by_name(username) do
      add_error(changeset, :preferred_username, "Username is already taken")
    else
      _ -> changeset
    end
  end

  # When we don't even have any preferred_username, don't even try validating preferred_username
  defp unique_username_validator(changeset), do: changeset

  @spec build_urls(Ecto.Changeset.t(), ActorType.t()) :: Ecto.Changeset.t()
  defp build_urls(changeset, type \\ :Person)

  defp build_urls(%Ecto.Changeset{changes: %{preferred_username: username}} = changeset, _type) do
    changeset
    |> put_change(:outbox_url, build_url(username, :outbox))
    |> put_change(:followers_url, build_url(username, :followers))
    |> put_change(:following_url, build_url(username, :following))
    |> put_change(:inbox_url, build_url(username, :inbox))
    |> put_change(:shared_inbox_url, "#{MobilizonWeb.Endpoint.url()}/inbox")
    |> put_change(:url, build_url(username, :page))
  end

  defp build_urls(%Ecto.Changeset{} = changeset, _type), do: changeset

  @doc """
  Builds an AP URL for an actor.
  """
  @spec build_url(String.t(), atom, keyword) :: String.t()
  def build_url(preferred_username, endpoint, args \\ [])

  def build_url(username, :inbox, _args), do: "#{build_url(username, :page)}/inbox"

  def build_url(preferred_username, :page, args) do
    Endpoint
    |> Routes.page_url(:actor, preferred_username, args)
    |> URI.decode()
  end

  def build_url(preferred_username, endpoint, args)
      when endpoint in [:outbox, :following, :followers] do
    Endpoint
    |> Routes.activity_pub_url(endpoint, preferred_username, args)
    |> URI.decode()
  end

  @spec build_relay_creation_attrs(map) :: map
  defp build_relay_creation_attrs(%{url: url, preferred_username: preferred_username}) do
    %{
      "name" => Config.get([:instance, :name], "Mobilizon"),
      "summary" =>
        Config.get(
          [:instance, :description],
          "An internal service actor for this Mobilizon instance"
        ),
      "url" => url,
      "keys" => Crypto.generate_rsa_2048_private_key(),
      "preferred_username" => preferred_username,
      "domain" => nil,
      "inbox_url" => "#{MobilizonWeb.Endpoint.url()}/inbox",
      "followers_url" => "#{url}/followers",
      "following_url" => "#{url}/following",
      "shared_inbox_url" => "#{MobilizonWeb.Endpoint.url()}/inbox",
      "type" => :Application
    }
  end
end
