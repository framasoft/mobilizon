defmodule Mobilizon.GraphQL.Schema.Actors.MemberType do
  @moduledoc """
  Schema representation for Member
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.{Group, Member}

  @desc """
  Represents a member of a group
  """
  object :member do
    field(:id, :id, description: "The member's ID")
    field(:parent, :group, description: "Of which the profile is member")
    field(:actor, :person, description: "Which profile is member of")
    field(:role, :member_role_enum, description: "The role of this membership")
    field(:invited_by, :person, description: "Who invited this member")
    field(:inserted_at, :naive_datetime, description: "When was this member created")
    field(:updated_at, :naive_datetime, description: "When was this member updated")
  end

  enum :member_role_enum do
    value(:not_approved)
    value(:invited)
    value(:member)
    value(:moderator)
    value(:administrator)
    value(:creator)
    value(:rejected)
  end

  object :paginated_member_list do
    field(:elements, list_of(:member), description: "A list of members")
    field(:total, :integer, description: "The total number of elements in the list")
  end

  object :member_mutations do
    @desc "Join a group"
    field :join_group, :member do
      arg(:group_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Group.join_group/3)
    end

    @desc "Leave a group"
    field :leave_group, :deleted_object do
      arg(:group_id, non_null(:id))

      resolve(&Group.leave_group/3)
    end

    @desc "Invite an actor to join the group"
    field :invite_member, :member do
      arg(:group_id, non_null(:id))
      arg(:target_actor_username, non_null(:string))

      resolve(&Member.invite_member/3)
    end

    @desc "Accept an invitation to a group"
    field :accept_invitation, :member do
      arg(:id, non_null(:id))

      resolve(&Member.accept_invitation/3)
    end

    @desc "Reject an invitation to a group"
    field :reject_invitation, :member do
      arg(:id, non_null(:id))

      resolve(&Member.reject_invitation/3)
    end

    @desc "Remove a member from a group"
    field :remove_member, :member do
      arg(:group_id, non_null(:id))
      arg(:member_id, non_null(:id))

      resolve(&Member.remove_member/3)
    end
  end
end
