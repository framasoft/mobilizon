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
  alias Eventos.Events.{Event, Participant, Request, Tag, Category, Session, Track}
  alias Eventos.Events.Event.TitleSlug
  alias Eventos.Accounts.Account
  alias Eventos.Groups.Group

  schema "events" do
    field :begins_on, Timex.Ecto.DateTimeWithTimezone
    field :description, :string
    field :ends_on, Timex.Ecto.DateTimeWithTimezone
    field :title, :string
    field :geom, Geo.Geometry
    field :slug, TitleSlug.Type
    field :state, :integer, default: 0
    field :status, :integer, default: 0
    field :public, :boolean, default: true
    field :thumbnail, :string
    field :large_image, :string
    field :publish_at, Timex.Ecto.DateTimeWithTimezone
    belongs_to :organizer_account, Account, [foreign_key: :organizer_account_id]
    belongs_to :organizer_group, Group, [foreign_key: :organizer_group_id]
    many_to_many :tags, Tag, join_through: "events_tags"
    belongs_to :category, Category
    many_to_many :participants, Account, join_through: Participant
    has_many :event_request, Request
    has_many :tracks, Track
    has_many :sessions, Session

    timestamps()
  end

  @doc false
  def changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:title, :description, :begins_on, :ends_on, :organizer_account_id, :organizer_group_id, :category_id, :state, :geom, :status, :public, :thumbnail, :large_image, :publish_at])
    |> cast_assoc(:tags)
    |> validate_required([:title, :description, :begins_on, :ends_on, :organizer_account_id, :category_id])
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end
end
