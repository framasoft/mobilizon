import EctoEnum

defenum(Mobilizon.Actors.MemberRoleEnum, :member_role_type, [
  :not_approved,
  :member,
  :moderator,
  :administrator,
  :creator
])

defmodule Mobilizon.Actors.Member do
  @moduledoc """
  Represents the membership of an actor to a group
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Mobilizon.Ecto

  alias Mobilizon.Actors.Member
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Repo

  schema "members" do
    field(:role, Mobilizon.Actors.MemberRoleEnum, default: :member)
    belongs_to(:parent, Actor)
    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc false
  def changeset(%Member{} = member, attrs) do
    member
    |> cast(attrs, [:role, :parent_id, :actor_id])
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

  @doc """
  Gets a single member of an actor (for example a group)
  """
  def can_be_joined(%Actor{type: :Group, openness: :invite_only}), do: false
  def can_be_joined(%Actor{type: :Group}), do: true

  @doc """
  Returns the list of administrator members for a group.
  """
  def list_administrator_members_for_group(id, page \\ nil, limit \\ nil) do
    Repo.all(
      from(
        m in Member,
        where: m.parent_id == ^id and (m.role == ^:creator or m.role == ^:administrator),
        preload: [:actor]
      )
      |> paginate(page, limit)
    )
  end

  @doc """
  Get all group ids where the actor_id is the last administrator
  """
  def list_group_id_where_last_administrator(actor_id) do
    in_query =
      from(
        m in Member,
        where: m.actor_id == ^actor_id and (m.role == ^:creator or m.role == ^:administrator),
        select: m.parent_id
      )

    Repo.all(
      from(
        m in Member,
        where: m.role == ^:creator or m.role == ^:administrator,
        join: m2 in subquery(in_query),
        on: m.parent_id == m2.parent_id,
        group_by: m.parent_id,
        select: m.parent_id,
        having: count(m.actor_id) == 1
      )
    )
  end

  @doc """
  Returns true if the member is an administrator (admin or creator) of the group
  """
  def is_administrator(%Member{role: :administrator}), do: {:is_admin, true}
  def is_administrator(%Member{role: :creator}), do: {:is_admin, true}
  def is_administrator(%Member{}), do: {:is_admin, false}
end
