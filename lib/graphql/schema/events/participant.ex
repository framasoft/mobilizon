defmodule Mobilizon.GraphQL.Schema.Events.ParticipantType do
  @moduledoc """
  Schema representation for Participant.
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.{Actors, Events}
  alias Mobilizon.GraphQL.Resolvers.Participant

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

    field(:metadata, :participant_metadata,
      description: "The metadata associated to this participant"
    )

    field(:inserted_at, :datetime, description: "The datetime this participant was created")
  end

  object :participant_metadata do
    field(:cancellation_token, :string,
      description: "The eventual token to leave an event when user is anonymous"
    )

    field(:message, :string, description: "The eventual message the participant left")
  end

  object :paginated_participant_list do
    field(:elements, list_of(:participant), description: "A list of participants")
    field(:total, :integer, description: "The total number of participants in the list")
  end

  enum :participant_role_enum do
    value(:not_approved)
    value(:not_confirmed)
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
      arg(:email, :string)
      arg(:message, :string)

      resolve(&Participant.actor_join_event/3)
    end

    @desc "Leave an event"
    field :leave_event, :deleted_participant do
      arg(:event_id, non_null(:id))
      arg(:actor_id, non_null(:id))
      arg(:token, :string)

      resolve(&Participant.actor_leave_event/3)
    end

    @desc "Accept a participation"
    field :update_participation, :participant do
      arg(:id, non_null(:id))
      arg(:role, non_null(:participant_role_enum))
      arg(:moderator_actor_id, non_null(:id))

      resolve(&Participant.update_participation/3)
    end

    @desc "Confirm a participation"
    field :confirm_participation, :participant do
      arg(:confirmation_token, non_null(:string))
      resolve(&Participant.confirm_participation_from_token/3)
    end
  end
end
