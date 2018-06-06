defmodule Eventos.Actors.Follower do
  @moduledoc """
  Represents the following of an actor to another actor
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Actors.Follower
  alias Eventos.Actors.Actor


  schema "followers" do
    field :approved, :boolean, default: false
    field :score, :integer, default: 1000
    belongs_to :target_actor, Actor
    belongs_to :actor, Actor

    timestamps()
  end

  @doc false
  def changeset(%Follower{} = member, attrs) do
    member
    |> cast(attrs, [:role, :approved, :target_actor_id, :actor_id])
    |> validate_required([:role, :approved, :target_actor_id, :actor_id])
  end
end
