defmodule MobilizonWeb.Schema.Events.ParticipantType do
  use Absinthe.Schema.Notation

  @desc "Represents a participant to an event"
  object :participant do
    field(:event, :event,
      resolve: dataloader(Events),
      description: "The event which the actor participates in"
    )

    field(:actor, :actor, description: "The actor that participates to the event")
    field(:role, :integer, description: "The role of this actor at this event")
  end
end
