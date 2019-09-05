import EctoEnum

defenum(Mobilizon.Actors.ActorTypeEnum, :actor_type, [
  :Person,
  :Application,
  :Group,
  :Organization,
  :Service
])

defenum(Mobilizon.Actors.ActorOpennessEnum, :actor_openness, [
  :invite_only,
  :moderated,
  :open
])

defenum(Mobilizon.Actors.ActorVisibilityEnum, :actor_visibility_type, [
  :public,
  :unlisted,
  # Probably unused
  :restricted,
  :private
])

defmodule Mobilizon.Actors.Actor do
  @moduledoc """
  Represents an actor (local and remote actors)
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Mobilizon.Actors
  alias Mobilizon.Users.User
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Events.{Event, FeedToken}
  alias Mobilizon.Media.File

  alias Mobilizon.Reports.{Report, Note}

  alias MobilizonWeb.Router.Helpers, as: Routes
  alias MobilizonWeb.Endpoint

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
    field(:domain, :string, default: nil)
    field(:summary, :string)
    field(:preferred_username, :string)
    field(:keys, :string)
    field(:manually_approves_followers, :boolean, default: false)
    field(:openness, Mobilizon.Actors.ActorOpennessEnum, default: :moderated)
    field(:visibility, Mobilizon.Actors.ActorVisibilityEnum, default: :private)
    field(:suspended, :boolean, default: false)
    # field(:openness, Mobilizon.Actors.ActorOpennessEnum, default: :moderated)
    has_many(:followers, Follower, foreign_key: :target_actor_id)
    has_many(:followings, Follower, foreign_key: :actor_id)
    has_many(:organized_events, Event, foreign_key: :organizer_actor_id)
    many_to_many(:memberships, Actor, join_through: Member)
    belongs_to(:user, User)
    has_many(:feed_tokens, FeedToken, foreign_key: :actor_id)
    embeds_one(:avatar, File, on_replace: :update)
    embeds_one(:banner, File, on_replace: :update)
    has_many(:created_reports, Report, foreign_key: :reporter_id)
    has_many(:subject_reports, Report, foreign_key: :reported_id)
    has_many(:report_notes, Note, foreign_key: :moderator_id)

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
      :user_id
    ])
    |> build_urls()
    |> cast_embed(:avatar)
    |> cast_embed(:banner)
    |> unique_username_validator()
    |> validate_required([:preferred_username, :keys, :suspended, :url])
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
    |> unique_constraint(:url, name: :actors_url_index)
  end

  @doc false
  def update_changeset(%Actor{} = actor, attrs) do
    actor
    |> Ecto.Changeset.cast(attrs, [
      :name,
      :summary,
      :keys,
      :manually_approves_followers,
      :suspended,
      :user_id
    ])
    |> cast_embed(:avatar)
    |> cast_embed(:banner)
    |> validate_required([:preferred_username, :keys, :suspended, :url])
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
    |> unique_constraint(:url, name: :actors_url_index)
  end

  @doc """
  Changeset for person registration
  """
  @spec registration_changeset(struct(), map()) :: Ecto.Changeset.t()
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
      :user_id
    ])
    |> build_urls()
    |> cast_embed(:avatar)
    |> cast_embed(:banner)
    # Needed because following constraint can't work for domain null values (local)
    |> unique_username_validator()
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
    |> unique_constraint(:url, name: :actors_url_index)
    |> validate_required([:preferred_username, :keys, :suspended, :url, :type])
  end

  # TODO : Use me !
  # @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
  @doc """
  Changeset for remote actor creation
  """
  @spec remote_actor_creation(map()) :: Ecto.Changeset.t()
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
        :manually_approves_followers
      ])
      |> validate_required([
        :url,
        :inbox_url,
        :type,
        :domain,
        :preferred_username,
        :keys
      ])
      |> cast_embed(:avatar)
      |> cast_embed(:banner)
      # Needed because following constraint can't work for domain null values (local)
      |> unique_username_validator()
      |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
      |> unique_constraint(:url, name: :actors_url_index)
      |> validate_length(:summary, max: 5000)
      |> validate_length(:preferred_username, max: 100)

    Logger.debug("Remote actor creation")
    Logger.debug(inspect(changes))
    changes
  end

  def relay_creation(%{url: url, preferred_username: preferred_username} = _params) do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)
    pem = [entry] |> :public_key.pem_encode() |> String.trim_trailing()

    vars = %{
      "name" => Mobilizon.CommonConfig.get([:instance, :name], "Mobilizon"),
      "summary" =>
        Mobilizon.CommonConfig.get(
          [:instance, :description],
          "An internal service actor for this Mobilizon instance"
        ),
      "url" => url,
      "keys" => pem,
      "preferred_username" => preferred_username,
      "domain" => nil,
      "inbox_url" => "#{MobilizonWeb.Endpoint.url()}/inbox",
      "followers_url" => "#{url}/followers",
      "following_url" => "#{url}/following",
      "shared_inbox_url" => "#{MobilizonWeb.Endpoint.url()}/inbox",
      "type" => :Application
    }

    cast(%Actor{}, vars, [
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
    ])
  end

  @doc """
  Changeset for group creation
  """
  @spec group_creation(struct(), map()) :: Ecto.Changeset.t()
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
      :preferred_username
    ])
    |> cast_embed(:avatar)
    |> cast_embed(:banner)
    |> build_urls(:Group)
    |> put_change(:domain, nil)
    |> put_change(:keys, Actors.create_keys())
    |> put_change(:type, :Group)
    |> unique_username_validator()
    |> validate_required([:url, :outbox_url, :inbox_url, :type, :preferred_username])
    |> unique_constraint(:preferred_username, name: :actors_preferred_username_domain_type_index)
    |> unique_constraint(:url, name: :actors_url_index)
    |> validate_length(:summary, max: 5000)
    |> validate_length(:preferred_username, max: 100)
  end

  defp unique_username_validator(
         %Ecto.Changeset{changes: %{preferred_username: username} = changes} = changeset
       ) do
    with nil <- Map.get(changes, :domain, nil),
         %Actor{preferred_username: _username} <- Actors.get_local_actor_by_name(username) do
      changeset |> add_error(:preferred_username, "Username is already taken")
    else
      _ -> changeset
    end
  end

  # When we don't even have any preferred_username, don't even try validating preferred_username
  defp unique_username_validator(changeset) do
    changeset
  end

  @spec build_urls(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  defp build_urls(changeset, type \\ :Person)

  defp build_urls(%Ecto.Changeset{changes: %{preferred_username: username}} = changeset, _type) do
    changeset
    |> put_change(
      :outbox_url,
      build_url(username, :outbox)
    )
    |> put_change(
      :followers_url,
      build_url(username, :followers)
    )
    |> put_change(
      :following_url,
      build_url(username, :following)
    )
    |> put_change(
      :inbox_url,
      build_url(username, :inbox)
    )
    |> put_change(:shared_inbox_url, "#{MobilizonWeb.Endpoint.url()}/inbox")
    |> put_change(:url, build_url(username, :page))
  end

  defp build_urls(%Ecto.Changeset{} = changeset, _type), do: changeset

  @doc """
  Build an AP URL for an actor
  """
  @spec build_url(String.t(), atom()) :: String.t()
  def build_url(preferred_username, endpoint, args \\ [])

  def build_url(preferred_username, :page, args) do
    Endpoint
    |> Routes.page_url(:actor, preferred_username, args)
    |> URI.decode()
  end

  def build_url(username, :inbox, _args), do: "#{build_url(username, :page)}/inbox"

  def build_url(preferred_username, endpoint, args)
      when endpoint in [:outbox, :following, :followers] do
    Endpoint
    |> Routes.activity_pub_url(endpoint, preferred_username, args)
    |> URI.decode()
  end

  @doc """
  Get a public key for a given ActivityPub actor ID (url)
  """
  @spec get_public_key_for_url(String.t()) :: {:ok, String.t()} | {:error, atom()}
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
    case :public_key.pem_decode(public_key_code) do
      [public_key_entry] ->
        {:ok, :public_key.pem_entry_decode(public_key_entry)}

      _err ->
        {:error, :pem_decode_error}
    end
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
    elements = Task.async(fn -> Repo.all(paginate(query, page, limit)) end)

    %{total: Task.await(total), elements: Task.await(elements)}
  end

  defp get_full_followers_query(%Actor{id: actor_id} = _actor) do
    from(
      a in Actor,
      join: f in Follower,
      on: a.id == f.actor_id,
      where: f.target_actor_id == ^actor_id
    )
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
    elements = Task.async(fn -> Repo.all(paginate(query, page, limit)) end)

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
        Actors.delete_follower(follow)

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

    Actors.create_follower(%{
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
    case Actors.get_follower(followed_actor, follower_actor) do
      nil -> false
      %Follower{} = follow -> follow
    end
  end

  @spec public_visibility?(struct()) :: boolean()
  def public_visibility?(%Actor{visibility: visibility}), do: visibility in [:public, :unlisted]

  @doc """
  Return the preferred_username with the eventual @domain suffix if it's a distant actor
  """
  @spec actor_acct_from_actor(struct()) :: String.t()
  def actor_acct_from_actor(%Actor{preferred_username: preferred_username, domain: domain}) do
    if is_nil(domain) do
      preferred_username
    else
      "#{preferred_username}@#{domain}"
    end
  end

  @doc """
  Returns the display name if available, or the preferred_username (with the eventual @domain suffix if it's a distant actor).
  """
  @spec display_name(struct()) :: String.t()
  def display_name(%Actor{name: name} = actor) do
    case name do
      nil -> actor_acct_from_actor(actor)
      "" -> actor_acct_from_actor(actor)
      name -> name
    end
  end

  @doc """
  Return display name and username

  ## Examples
      iex> display_name_and_username(%Actor{name: "Thomas C", preferred_username: "tcit", domain: nil})
      "Thomas (tcit)"

      iex> display_name_and_username(%Actor{name: "Thomas C", preferred_username: "tcit", domain: "framapiaf.org"})
      "Thomas (tcit@framapiaf.org)"

      iex> display_name_and_username(%Actor{name: nil, preferred_username: "tcit", domain: "framapiaf.org"})
      "tcit@framapiaf.org"

  """
  @spec display_name_and_username(struct()) :: String.t()
  def display_name_and_username(%Actor{name: nil} = actor), do: actor_acct_from_actor(actor)
  def display_name_and_username(%Actor{name: ""} = actor), do: actor_acct_from_actor(actor)

  def display_name_and_username(%Actor{name: name} = actor),
    do: name <> " (" <> actor_acct_from_actor(actor) <> ")"

  @doc """
  Clear multiple caches for an actor
  """
  @spec clear_cache(struct()) :: {:ok, true}
  def clear_cache(%Actor{preferred_username: preferred_username, domain: nil}) do
    Cachex.del(:activity_pub, "actor_" <> preferred_username)
    Cachex.del(:feed, "actor_" <> preferred_username)
    Cachex.del(:ics, "actor_" <> preferred_username)
  end
end
