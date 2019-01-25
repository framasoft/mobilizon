defmodule MobilizonWeb.Schema.Events.ParticipantType do
  @moduledoc """
  Schema representation for Participant
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias MobilizonWeb.Resolvers

  @desc "Represents a participant to an event"
  object :participant do
    field(:event, :event,
      resolve: dataloader(Events),
      description: "The event which the actor participates in"
    )

    field(:actor, :actor, description: "The actor that participates to the event")
    field(:role, :integer, description: "The role of this actor at this event")
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
end
