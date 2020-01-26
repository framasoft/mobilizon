defmodule Mobilizon.GraphQL.Schema.Actors.MemberType do
  @moduledoc """
  Schema representation for Member
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Group

  @desc """
  Represents a member of a group
  """
  object :member do
    field(:parent, :group, description: "Of which the profile is member")
    field(:actor, :person, description: "Which profile is member of")
    field(:role, :integer, description: "The role of this membership")
  end

  @desc "Represents a deleted member"
  object :deleted_member do
    field(:parent, :deleted_object)
    field(:actor, :deleted_object)
  end

  object :member_mutations do
    @desc "Join a group"
    field :join_group, :member do
      arg(:group_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Group.join_group/3)
    end

    @desc "Leave an event"
    field :leave_group, :deleted_member do
      arg(:group_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Group.leave_group/3)
    end
  end
end
