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

  @desc """
  Metadata about a participant
  """
  object :participant_metadata do
    field(:cancellation_token, :string,
      description: "The eventual token to leave an event when user is anonymous"
    )

    field(:message, :string, description: "The eventual message the participant left")
    field(:locale, :string, description: "The participant's locale")
  end

  @desc """
  A paginated list of participants
  """
  object :paginated_participant_list do
    field(:elements, list_of(:participant), description: "A list of participants")
    field(:total, :integer, description: "The total number of participants in the list")
  end

  @desc """
  The possible values for a participant role
  """
  enum :participant_role_enum do
    value(:not_approved, description: "The participant has not been approved")
    value(:not_confirmed, description: "The participant has not confirmed their participation")
    value(:participant, description: "The participant is a regular participant")
    value(:moderator, description: "The participant is an event moderator")
    value(:administrator, description: "The participant is an event administrator")
    value(:creator, description: "The participant is an event creator")
    value(:rejected, description: "The participant has been rejected from this event")
  end

  @desc "Represents a deleted participant"
  object :deleted_participant do
    field(:id, :id, description: "The participant ID")
    field(:event, :deleted_object, description: "The participant's event")
    field(:actor, :deleted_object, description: "The participant's actor")
  end

  object :participant_mutations do
    @desc "Join an event"
    field :join_event, :participant do
      arg(:event_id, non_null(:id), description: "The event ID that is joined")
      arg(:actor_id, non_null(:id), description: "The actor ID for the participant")
      arg(:email, :string, description: "The anonymous participant's email")
      arg(:message, :string, description: "The anonymous participant's message")
      arg(:locale, :string, description: "The anonymous participant's locale")

      resolve(&Participant.actor_join_event/3)
    end

    @desc "Leave an event"
    field :leave_event, :deleted_participant do
      arg(:event_id, non_null(:id), description: "The event ID the participant left")
      arg(:actor_id, non_null(:id), description: "The actor ID for the participant")
      arg(:token, :string, description: "The anonymous participant participation token")

      resolve(&Participant.actor_leave_event/3)
    end

    @desc "Update a participation"
    field :update_participation, :participant do
      arg(:id, non_null(:id), description: "The participant ID")
      arg(:role, non_null(:participant_role_enum), description: "The participant new role")

      resolve(&Participant.update_participation/3)
    end

    @desc "Confirm a participation"
    field :confirm_participation, :participant do
      arg(:confirmation_token, non_null(:string), description: "The participation token")
      resolve(&Participant.confirm_participation_from_token/3)
    end
  end
end
