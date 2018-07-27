defmodule Eventos.Actors.Member do
  @moduledoc """
  Represents the membership of an actor to a group
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Actors.Member
  alias Eventos.Actors.Actor

  @primary_key false
  schema "members" do
    field(:approved, :boolean, default: true)
    # 0 : Member, 1 : Moderator, 2 : Admin
    field(:role, :integer, default: 0)
    belongs_to(:parent, Actor)
    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc false
  def changeset(%Member{} = member, attrs) do
    member
    |> cast(attrs, [:role, :approved, :parent_id, :actor_id])
    |> validate_required([:parent_id, :actor_id])
  end
end
