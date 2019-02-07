import EctoEnum

defenum(Mobilizon.Events.ParticipantRoleEnum, :participant_role_type, [
  :not_approved,
  :participant,
  :moderator,
  :administrator,
  :creator
])

defmodule Mobilizon.Events.Participant do
  @moduledoc """
  Represents a participant, an actor participating to an event
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.{Participant, Event}
  alias Mobilizon.Actors.Actor

  @primary_key false
  schema "participants" do
    field(:role, Mobilizon.Events.ParticipantRoleEnum, default: :participant)
    belongs_to(:event, Event, primary_key: true)
    belongs_to(:actor, Actor, primary_key: true)

    timestamps()
  end

  @doc false
  def changeset(%Participant{} = participant, attrs) do
    participant
    |> Ecto.Changeset.cast(attrs, [:role, :event_id, :actor_id])
    |> validate_required([:role, :event_id, :actor_id])
  end
end
