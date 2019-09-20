defmodule MobilizonWeb.Schema.Events.ParticipantType do
  @moduledoc """
  Schema representation for Participant
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias MobilizonWeb.Resolvers
  alias Mobilizon.Events
  alias Mobilizon.Actors

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
  end

  @desc "Represents a deleted participant"
  object :deleted_participant do
    field(:id, :id)
    field(:event, :deleted_object)
    field(:actor, :deleted_object)
  end

  object :participant_queries do
    @desc "Get all participants for an event uuid"
    field :participants, list_of(:participant) do
      arg(:uuid, non_null(:uuid))
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Event.list_participants_for_event/3)
    end
  end

  object :participant_mutations do
    @desc "Join an event"
    field :join_event, :participant do
      arg(:event_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Resolvers.Event.actor_join_event/3)
    end

    @desc "Leave an event"
    field :leave_event, :deleted_participant do
      arg(:event_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Resolvers.Event.actor_leave_event/3)
    end

    @desc "Accept a participation"
    field :accept_participation, :participant do
      arg(:id, non_null(:id))
      arg(:moderator_actor_id, non_null(:id))

      resolve(&Resolvers.Event.accept_participation/3)
    end

    @desc "Reject a participation"
    field :reject_participation, :deleted_participant do
      arg(:id, non_null(:id))
      arg(:moderator_actor_id, non_null(:id))

      resolve(&Resolvers.Event.reject_participation/3)
    end
  end
end
