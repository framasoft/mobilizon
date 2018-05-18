defmodule Eventos.Actors.Member do
  @moduledoc """
  Represents the membership of an actor to a group
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Actors.Member
  alias Eventos.Actors.Actor


  schema "members" do
    field :approved, :boolean
    field :role, :integer
    belongs_to :parent, Actor
    belongs_to :actor, Actor

    timestamps()
  end

  @doc false
  def changeset(%Member{} = member, attrs) do
    member
    |> cast(attrs, [:role])
    |> validate_required([:role])
  end
end
