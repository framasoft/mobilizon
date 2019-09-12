defmodule Mobilizon.Events.Track do
  @moduledoc """
  Represents a track for an event (such as a theme) having multiple sessions.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Events.{Event, Session}

  @type t :: %__MODULE__{
          color: String.t(),
          description: String.t(),
          name: String.t(),
          event: Event.t(),
          sessions: [Session.t()]
        }

  @required_attrs [:name, :description, :color]
  @optional_attrs [:event_id]
  @attrs @required_attrs ++ @optional_attrs

  schema "tracks" do
    field(:color, :string)
    field(:description, :string)
    field(:name, :string)

    belongs_to(:event, Event)
    has_many(:sessions, Session)

    timestamps()
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = track, attrs) do
    track
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
  end
end
