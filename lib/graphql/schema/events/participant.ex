defmodule Mobilizon.GraphQL.Schema.Events.ParticipantType do
  @moduledoc """
  Schema representation for Participant.
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.GraphQL.Resolvers.Event

  @desc "Represents a participant to an event"
  object :participant do
    field(:id, :id, description: "The participation ID")

    field(
      :event,
      :event,
      resolve: dataloader(Events),
      description: "The event which the actor participates in"
    )

    field(
      :actor,
      :actor,
      resolve: dataloader(Actors),
      description: "The actor that participates to the event"
    )

    field(:role, :participant_role_enum, description: "The role of this actor at this event")
  end

  enum :participant_role_enum do
    value(:not_approved)
    value(:participant)
    value(:moderator)
    value(:administrator)
    value(:creator)
    value(:rejected)
  end

  @desc "Represents a deleted participant"
  object :deleted_participant do
    field(:id, :id)
    field(:event, :deleted_object)
    field(:actor, :deleted_object)
  end

  object :participant_mutations do
    @desc "Join an event"
    field :join_event, :participant do
      arg(:event_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Event.actor_join_event/3)
    end

    @desc "Leave an event"
    field :leave_event, :deleted_participant do
      arg(:event_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Event.actor_leave_event/3)
    end

    @desc "Accept a participation"
    field :update_participation, :participant do
      arg(:id, non_null(:id))
      arg(:role, non_null(:participant_role_enum))
      arg(:moderator_actor_id, non_null(:id))

      resolve(&Event.update_participation/3)
    end
  end
end
