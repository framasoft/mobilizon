defmodule Mobilizon.Actors.Actor do
  @moduledoc """
  Represents an actor (local and remote).
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.{Actors, Addresses, Config, Crypto, Mention, Share}
  alias Mobilizon.Actors.{ActorOpenness, ActorType, ActorVisibility, Follower, Member}
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.{Event, FeedToken}
  alias Mobilizon.Medias.File
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Users.User

  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes
  import Mobilizon.Web.Gettext, only: [dgettext: 2]

  require Logger

  @type t :: %__MODULE__{
          url: String.t(),
          outbox_url: String.t(),
          inbox_url: String.t(),
          following_url: String.t(),
          followers_url: String.t(),
          shared_inbox_url: String.t(),
          resources_url: String.t(),
          posts_url: String.t(),
          events_url: String.t(),
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
          comments: [Comment.t()],
          feed_tokens: [FeedToken.t()],
          created_reports: [Report.t()],
          subject_reports: [Report.t()],
          report_notes: [Note.t()],
          mentions: [Mention.t()],
          shares: [Share.t()],
          owner_shares: [Share.t()],
          memberships: [t],
          last_refreshed_at: DateTime.t(),
          physical_address: Address.t()
        }

  @required_attrs [:preferred_username, :keys, :suspended, :url]
  @optional_attrs [
    :outbox_url,
    :inbox_url,
    :shared_inbox_url,
    :following_url,
    :followers_url,
    :posts_url,
    :events_url,
    :todos_url,
    :discussions_url,
    :type,
    :name,
    :domain,
    :summary,
    :manually_approves_followers,
    :last_refreshed_at,
    :user_id,
    :physical_address_id,
    :visibility
  ]
  @attrs @required_attrs ++ @optional_attrs

  @update_required_attrs @required_attrs -- [:url]
  @update_optional_attrs [
    :name,
    :summary,
    :manually_approves_followers,
    :user_id,
    :visibility,
    :openness
  ]
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
    :members_url,
    :resources_url,
    :posts_url,
    :todos_url,
    :events_url,
    :discussions_url,
    :name,
    :summary,
    :manually_approves_followers,
    :visibility,
    :openness
  ]
  @remote_actor_creation_attrs @remote_actor_creation_required_attrs ++
                                 @remote_actor_creation_optional_attrs

  @group_creation_required_attrs [
    :url,
    :outbox_url,
    :inbox_url,
    :type,
    :preferred_username,
    :members_url
  ]
  @group_creation_optional_attrs [
    :shared_inbox_url,
    :name,
    :domain,
    :summary,
    :visibility,
    :openness
  ]
  @group_creation_attrs @group_creation_required_attrs ++ @group_creation_optional_attrs

  schema "actors" do
    field(:url, :string)

    field(:outbox_url, :string)
    field(:inbox_url, :string)
    field(:following_url, :string)
    field(:followers_url, :string)
    field(:shared_inbox_url, :string)
    field(:members_url, :string)
    field(:resources_url, :string)
    field(:posts_url, :string)
    field(:events_url, :string)
    field(:todos_url, :string)
    field(:discussions_url, :string)

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
    field(:last_refreshed_at, :utc_datetime)

    embeds_one(:avatar, File, on_replace: :update)
    embeds_one(:banner, File, on_replace: :update)
    belongs_to(:user, User)
    belongs_to(:physical_address, Address, on_replace: :nilify)
    has_many(:followers, Follower, foreign_key: :target_actor_id)
    has_many(:followings, Follower, foreign_key: :actor_id)
    has_many(:organized_events, Event, foreign_key: :organizer_actor_id)
    has_many(:comments, Comment, foreign_key: :actor_id)
    has_many(:feed_tokens, FeedToken, foreign_key: :actor_id)
    has_many(:created_reports, Report, foreign_key: :reporter_id)
    has_many(:subject_reports, Report, foreign_key: :reported_id)
    has_many(:report_notes, Note, foreign_key: :moderator_id)
    has_many(:mentions, Mention)
    has_many(:shares, Share, foreign_key: :actor_id)
    has_many(:owner_shares, Share, foreign_key: :owner_actor_id)
    many_to_many(:memberships, __MODULE__, join_through: Member)

    timestamps()
  end

  @doc """
  Checks whether actor visibility is public.
  """
  @spec is_public_visibility?(t) :: boolean
  def is_public_visibility?(%__MODULE__{visibility: visibility}) do
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
    "#{name} (@#{preferred_username_and_domain(actor)})"
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
    |> common_changeset(attrs)
    |> unique_username_validator()
    |> validate_required(@required_attrs)
  end

  @doc false
  @spec update_changeset(t, map) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = actor, attrs) do
    actor
    |> cast(attrs, @update_attrs)
    |> common_changeset(attrs)
    |> validate_required(@update_required_attrs)
  end

  @doc false
  @spec delete_changeset(t) :: Ecto.Changeset.t()
  def delete_changeset(%__MODULE__{} = actor) do
    actor
    |> change()
    |> put_change(:name, nil)
    |> put_change(:summary, nil)
    |> put_change(:suspended, true)
    |> put_change(:avatar, nil)
    |> put_change(:banner, nil)
    |> put_change(:user_id, nil)
  end

  @doc """
  Changeset for person registration.
  """
  @spec registration_changeset(t, map) :: Ecto.Changeset.t()
  def registration_changeset(%__MODULE__{} = actor, attrs) do
    actor
    |> cast(attrs, @registration_attrs)
    |> build_urls()
    |> common_changeset(attrs)
    |> unique_username_validator()
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
      |> common_changeset(attrs)
      |> unique_username_validator()
      |> validate_required(:domain)
      |> validate_length(:summary, max: 5000)
      |> validate_length(:preferred_username, max: 100)

    Logger.debug("Remote actor creation: #{inspect(changeset)}")

    changeset
  end

  @spec common_changeset(Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  defp common_changeset(%Ecto.Changeset{} = changeset, attrs) do
    changeset
    |> cast_embed(:avatar)
    |> cast_embed(:banner)
    |> put_address(attrs)
    |> unique_constraint(:url, name: :actors_url_index)
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
    |> validate_format(:preferred_username, ~r/[a-z0-9_]+/)
    |> put_change(:last_refreshed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for group creation
  """
  @spec group_creation_changeset(t, map) :: Ecto.Changeset.t()
  def group_creation_changeset(%__MODULE__{} = actor, params) do
    actor
    |> cast(params, @group_creation_attrs)
    |> build_urls(:Group)
    |> common_changeset(params)
    |> put_change(:domain, nil)
    |> put_change(:keys, Crypto.generate_rsa_2048_private_key())
    |> put_change(:type, :Group)
    |> unique_username_validator()
    |> validate_required(@group_creation_required_attrs)
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
      add_error(
        changeset,
        :preferred_username,
        dgettext("errors", "This username is already taken.")
      )
    else
      _ -> changeset
    end
  end

  # When we don't even have any preferred_username, don't even try validating preferred_username
  defp unique_username_validator(changeset), do: changeset

  @spec build_urls(Ecto.Changeset.t(), ActorType.t()) :: Ecto.Changeset.t()
  defp build_urls(changeset, type \\ :Person)

  defp build_urls(%Ecto.Changeset{changes: %{preferred_username: username}} = changeset, type) do
    changeset
    |> put_change(:outbox_url, build_url(username, :outbox))
    |> put_change(:followers_url, build_url(username, :followers))
    |> put_change(:following_url, build_url(username, :following))
    |> put_change(:inbox_url, build_url(username, :inbox))
    |> put_change(:shared_inbox_url, "#{Endpoint.url()}/inbox")
    |> put_change(:members_url, if(type == :Group, do: build_url(username, :members), else: nil))
    |> put_change(
      :resources_url,
      if(type == :Group, do: build_url(username, :resources), else: nil)
    )
    |> put_change(:todos_url, if(type == :Group, do: build_url(username, :todos), else: nil))
    |> put_change(:posts_url, if(type == :Group, do: build_url(username, :posts), else: nil))
    |> put_change(:events_url, if(type == :Group, do: build_url(username, :events), else: nil))
    |> put_change(
      :discussions_url,
      if(type == :Group, do: build_url(username, :discussions), else: nil)
    )
    |> put_change(:url, build_url(username, :page))
  end

  defp build_urls(%Ecto.Changeset{} = changeset, _type), do: changeset

  @doc """
  Builds an AP URL for an actor.
  """
  @spec build_url(String.t(), atom, keyword) :: String.t()
  def build_url(preferred_username, endpoint, args \\ [])

  def build_url(username, :inbox, _args), do: "#{build_url(username, :page)}/inbox"

  # Relay has a special URI
  def build_url("relay", :page, _args),
    do: Endpoint |> Routes.activity_pub_url(:relay) |> URI.decode()

  def build_url(preferred_username, endpoint, args)
      when endpoint in [:page, :resources, :posts, :discussions, :events, :todos] do
    endpoint = if endpoint == :page, do: :actor, else: endpoint

    Endpoint
    |> Routes.page_url(endpoint, preferred_username, args)
    |> URI.decode()
  end

  def build_url(preferred_username, endpoint, args)
      when endpoint in [:outbox, :following, :followers, :members] do
    Endpoint
    |> Routes.activity_pub_url(endpoint, preferred_username, args)
    |> URI.decode()
  end

  @spec build_relay_creation_attrs :: Ecto.Changeset.t()
  def build_relay_creation_attrs do
    data = %{
      "name" => Config.get([:instance, :name], "Mobilizon"),
      "summary" =>
        Config.get(
          [:instance, :description],
          "An internal service actor for this Mobilizon instance"
        ),
      "keys" => Crypto.generate_rsa_2048_private_key(),
      "preferred_username" => "relay",
      "domain" => nil,
      "visibility" => :public,
      "type" => :Application
    }

    %__MODULE__{}
    |> Ecto.Changeset.cast(data, @attrs)
    |> build_urls()
    # Can use sharedinbox directly
    |> put_change(:inbox_url, "#{Endpoint.url()}/inbox")
    |> unique_username_validator()
  end

  @spec build_anonymous_actor_creation_attrs :: Ecto.Changeset.t()
  def build_anonymous_actor_creation_attrs do
    data = %{
      "name" => "Mobilizon Anonymous Actor",
      "summary" => "A fake person for anonymous participations",
      "keys" => Crypto.generate_rsa_2048_private_key(),
      "preferred_username" => "anonymous",
      "domain" => nil,
      "type" => :Person
    }

    %__MODULE__{}
    |> Ecto.Changeset.cast(data, @attrs)
    |> build_urls()
  end

  # In case the provided addresses is an existing one
  @spec put_address(Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  defp put_address(%Ecto.Changeset{} = changeset, %{
         physical_address: %{id: id} = _physical_address
       })
       when not is_nil(id) do
    case Addresses.get_address(id) do
      %Address{} = address ->
        put_assoc(changeset, :physical_address, address)

      _ ->
        cast_assoc(changeset, :physical_address)
    end
  end

  # In case it's a new address but the origin_id is an existing one
  defp put_address(%Ecto.Changeset{} = changeset, %{physical_address: %{origin_id: origin_id}})
       when not is_nil(origin_id) do
    case Addresses.get_address_by_origin_id(origin_id) do
      %Address{} = address ->
        put_assoc(changeset, :physical_address, address)

      _ ->
        cast_assoc(changeset, :physical_address)
    end
  end

  # In case it's a new address without any origin_id (manual)
  defp put_address(%Ecto.Changeset{} = changeset, _attrs) do
    cast_assoc(changeset, :physical_address)
  end
end
