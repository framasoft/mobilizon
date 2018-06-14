defmodule Eventos.Events.Event.TitleSlug do
  @moduledoc """
  Generates a slug for an event title
  """
  alias Eventos.Events.Event
  import Ecto.Query
  alias Eventos.Repo
  use EctoAutoslugField.Slug, from: :title, to: :slug

  def build_slug(sources, changeset) do
    slug = super(sources, changeset)
    build_unique_slug(slug, changeset)
  end

  defp build_unique_slug(slug, changeset) do
    query = from e in Event,
                 where: e.slug == ^slug

    case Repo.one(query) do
      nil -> slug
      _event ->
        slug
        |> Eventos.Slug.increment_slug()
        |> build_unique_slug(changeset)
    end
  end
end

defmodule Eventos.Events.Event do
  @moduledoc """
  Represents an event
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{Event, Participant, Tag, Category, Session, Track}
  alias Eventos.Events.Event.TitleSlug
  alias Eventos.Actors.Actor
  alias Eventos.Addresses.Address

  schema "events" do
    field :url, :string
    field :local, :boolean, default: true
    field :begins_on, Timex.Ecto.DateTimeWithTimezone
    field :description, :string
    field :ends_on, Timex.Ecto.DateTimeWithTimezone
    field :title, :string
    field :slug, TitleSlug.Type
    field :state, :integer, default: 0
    field :status, :integer, default: 0
    field :public, :boolean, default: true
    field :thumbnail, :string
    field :large_image, :string
    field :publish_at, Timex.Ecto.DateTimeWithTimezone
    field :uuid, Ecto.UUID, default: Ecto.UUID.generate()
    belongs_to :organizer_actor, Actor, [foreign_key: :organizer_actor_id]
    belongs_to :attributed_to, Actor, [foreign_key: :attributed_to_id]
    many_to_many :tags, Tag, join_through: "events_tags"
    belongs_to :category, Category
    many_to_many :participants, Actor, join_through: Participant
    has_many :tracks, Track
    has_many :sessions, Session
    belongs_to :address, Address

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Event{} = event, attrs) do
    uuid = Ecto.UUID.generate()

    # TODO : check what's the use here. Tests ?
    actor_url = if Map.has_key?(attrs, :organizer_actor) do
      attrs.organizer_actor.preferred_username
    else
      ""
    end
    event
    |> cast(attrs, [:title, :description, :url, :begins_on, :ends_on, :organizer_actor_id, :category_id, :state, :status, :public, :thumbnail, :large_image, :publish_at])
    |> cast_assoc(:tags)
    |> cast_assoc(:address)
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
    |> put_change(:uuid, uuid)
    |> put_change(:url, "#{EventosWeb.Endpoint.url()}/@#{actor_url}/#{uuid}")
    |> validate_required([:title, :description, :begins_on, :ends_on, :organizer_actor_id, :category_id, :url, :uuid])
  end
end
