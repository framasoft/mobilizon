defmodule Mobilizon.Actors.Member do
  @moduledoc """
  Represents the membership of an actor to a group
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Actors.Member
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Repo

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
    |> unique_constraint(:parent_id, name: :members_actor_parent_unique_index)
  end

  @doc """
  Gets a single member of an actor (for example a group)
  """
  def get_member(actor_id, parent_id) do
    case Repo.get_by(Member, actor_id: actor_id, parent_id: parent_id) do
      nil -> {:error, :member_not_found}
      member -> {:ok, member}
    end
  end

  def is_administrator(%Member{role: 2} = member) do
    {:is_admin, true}
  end

  def is_administrator(%Member{}) do
    {:is_admin, false}
  end
end
