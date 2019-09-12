defmodule Mobilizon.Actors.Member do
  @moduledoc """
  Represents the membership of an actor to a group.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.{Actor, MemberRole}

  @type t :: %__MODULE__{
          role: MemberRole.t(),
          parent: Actor.t(),
          actor: Actor.t()
        }

  @required_attrs [:parent_id, :actor_id]
  @optional_attrs [:role]
  @attrs @required_attrs ++ @optional_attrs

  schema "members" do
    field(:role, MemberRole, default: :member)

    belongs_to(:parent, Actor)
    belongs_to(:actor, Actor)

    timestamps()
  end

  @doc """
  Gets the default member role depending on the actor openness.
  """
  @spec get_default_member_role(Actor.t()) :: atom
  def get_default_member_role(%Actor{openness: :open}), do: :member
  def get_default_member_role(%Actor{}), do: :not_approved

  @doc """
  Checks whether the actor can be joined to the group.
  """
  def can_be_joined(%Actor{type: :Group, openness: :invite_only}), do: false
  def can_be_joined(%Actor{type: :Group}), do: true

  @doc """
  Checks whether the member is an administrator (admin or creator) of the group.
  """
  def is_administrator(%__MODULE__{role: :administrator}), do: {:is_admin, true}
  def is_administrator(%__MODULE__{role: :creator}), do: {:is_admin, true}
  def is_administrator(%__MODULE__{}), do: {:is_admin, false}

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = member, attrs) do
    member
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:parent_id, name: :members_actor_parent_unique_index)
  end
end
