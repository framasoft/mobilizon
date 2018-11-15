defmodule Mobilizon.Events.Participant do
  @moduledoc """
  Represents a participant, an actor participating to an event
  """
  use Mobilizon.Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.{Participant, Event}
  alias Mobilizon.Actors.Actor

  @primary_key false
  schema "participants" do
    # 0 : not_approved, 1 : participant, 2 : moderator, 3 : administrator, 4 : creator
    field(:role, :integer, default: 0)
    belongs_to(:event, Event, primary_key: true)
    belongs_to(:actor, Actor, primary_key: true)

    timestamps()
  end

  @doc false
  def changeset(%Participant{} = participant, attrs) do
    participant
    |> cast(attrs, [:role, :event_id, :actor_id])
    |> validate_required([:role, :event_id, :actor_id])
  end
end
