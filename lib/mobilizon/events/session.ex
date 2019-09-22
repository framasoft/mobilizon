defmodule Mobilizon.Events.Session do
  @moduledoc """
  Represents a session for an event (such as a talk at a conference).
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.{Event, Track}

  @type t :: %__MODULE__{
          audios_urls: String.t(),
          language: String.t(),
          long_abstract: String.t(),
          short_abstract: String.t(),
          slides_url: String.t(),
          subtitle: String.t(),
          title: String.t(),
          videos_urls: String.t(),
          begins_on: DateTime.t(),
          ends_on: DateTime.t(),
          event: Event.t(),
          track: Track.t()
        }

  @required_attrs [
    :title,
    :subtitle,
    :short_abstract,
    :long_abstract,
    :language,
    :slides_url,
    :videos_urls,
    :audios_urls
  ]
  @optional_attrs [:event_id, :track_id]
  @attrs @required_attrs ++ @optional_attrs

  schema "sessions" do
    field(:audios_urls, :string)
    field(:language, :string)
    field(:long_abstract, :string)
    field(:short_abstract, :string)
    field(:slides_url, :string)
    field(:subtitle, :string)
    field(:title, :string)
    field(:videos_urls, :string)
    field(:begins_on, :utc_datetime)
    field(:ends_on, :utc_datetime)

    belongs_to(:event, Event)
    belongs_to(:track, Track)

    timestamps()
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = session, attrs) do
    session
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
