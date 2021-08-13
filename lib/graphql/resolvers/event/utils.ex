defmodule Mobilizon.GraphQL.Resolvers.Event.Utils do
  @moduledoc """
  Tools to test permission on events
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.Permission

  def can_event_be_updated_by?(
        %Event{attributed_to: %Actor{type: :Group}} = event,
        %Actor{} = actor_member
      ) do
    Permission.can_update_group_object?(actor_member, event)
  end

  def can_event_be_updated_by?(
        %Event{} = event,
        %Actor{id: actor_member_id}
      ) do
    Event.can_be_managed_by?(event, actor_member_id)
  end

  def can_event_be_deleted_by?(
        %Event{attributed_to: %Actor{type: :Group}} = event,
        %Actor{} = actor_member
      ) do
    Permission.can_delete_group_object?(actor_member, event)
  end

  def can_event_be_deleted_by?(%Event{} = event, %Actor{id: actor_member_id}) do
    Event.can_be_managed_by?(event, actor_member_id)
  end
end
