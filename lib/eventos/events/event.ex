defmodule Eventos.Events.Event.TitleSlug do
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
        |> increment_slug
        |> build_unique_slug(changeset)
    end
  end

  defp increment_slug(slug) do
    case List.pop_at(String.split(slug, "-"), -1) do
      {nil, _} ->
        slug
      {suffix, slug_parts} ->
        case Integer.parse(suffix) do
          {id, _} -> Enum.join(slug_parts, "-") <> "-" <> Integer.to_string(id + 1)
          :error -> slug <> "-1"
        end
    end
  end
end

defmodule Eventos.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{Event, Participant, Request, Tag, Session, Track}
  alias Eventos.Events.Event.TitleSlug
  alias Eventos.Accounts.Account

  schema "events" do
    field :begins_on, Timex.Ecto.DateTimeWithTimezone
    field :description, :string
    field :ends_on, Timex.Ecto.DateTimeWithTimezone
    field :title, :string
    field :geom, Geo.Geometry
    field :slug, TitleSlug.Type
    field :state, :integer, default: 0
    field :public, :boolean, default: true
    field :thumbnail, :string
    field :large_image, :string
    field :publish_at, Timex.Ecto.DateTimeWithTimezone
    belongs_to :organizer, Account, [foreign_key: :organizer_id]
    has_many :tags, Tag
    many_to_many :participants, Account, join_through: Participant
    has_many :event_request, Request
    has_many :tracks, Track
    has_many :sessions, Session

    timestamps()
  end

  @doc false
  def changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:title, :description, :begins_on, :ends_on, :organizer_id])
    |> validate_required([:title, :description, :begins_on, :ends_on, :organizer_id])
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end
end