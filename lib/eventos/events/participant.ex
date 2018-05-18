defmodule Eventos.Events.Participant do
  @moduledoc """
  Represents a participant, an actor participating to an event
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{Participant, Event}
  alias Eventos.Actors.Actor

  @primary_key false
  schema "participants" do
    field :role, :integer
    field :approved, :boolean
    belongs_to :event, Event, primary_key: true
    belongs_to :actor, Actor, primary_key: true

    timestamps()
  end

  @doc false
  def changeset(%Participant{} = participant, attrs) do
    participant
    |> cast(attrs, [:role, :event_id, :actor_id])
    |> validate_required([:role, :event_id, :actor_id])
  end
end
