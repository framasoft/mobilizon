defmodule Mobilizon.Events.Track do
  @moduledoc """
  Represents a track for an event (such as a theme) having multiple sessions
  """
  use Mobilizon.Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.{Track, Event, Session}

  schema "tracks" do
    field(:color, :string)
    field(:description, :string)
    field(:name, :string)
    belongs_to(:event, Event)
    has_many(:sessions, Session)

    timestamps()
  end

  @doc false
  def changeset(%Track{} = track, attrs) do
    track
    |> cast(attrs, [:name, :description, :color, :event_id])
    |> validate_required([:name, :description, :color])
  end
end
