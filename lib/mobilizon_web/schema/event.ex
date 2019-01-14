defmodule MobilizonWeb.Schema.EventType do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import_types(MobilizonWeb.Schema.AddressType)
  import_types(MobilizonWeb.Schema.Events.ParticipantType)
  import_types(MobilizonWeb.Schema.Events.CategoryType)

  @desc "An event"
  object :event do
    field(:uuid, :uuid, description: "The Event UUID")
    field(:url, :string, description: "The ActivityPub Event URL")
    field(:local, :boolean, description: "Whether the event is local or not")
    field(:title, :string, description: "The event's title")
    field(:description, :string, description: "The event's description")
    field(:begins_on, :datetime, description: "Datetime for when the event begins")
    field(:ends_on, :datetime, description: "Datetime for when the event ends")
    field(:state, :integer, description: "State of the event")
    field(:status, :integer, description: "Status of the event")
    field(:public, :boolean, description: "Whether the event is public or not")
    # TODO replace me with picture object
    field(:thumbnail, :string, description: "A thumbnail picture for the event")
    # TODO replace me with banner
    field(:large_image, :string, description: "A large picture for the event")
    field(:publish_at, :datetime, description: "When the event was published")
    field(:physical_address, :physical_address, description: "The type of the event's address")
    field(:online_address, :online_address, description: "Online address of the event")
    field(:phone_address, :phone_address, description: "Phone address for the event")

    field(:organizer_actor, :person,
      resolve: dataloader(Actors),
      description: "The event's organizer (as a person)"
    )

    field(:attributed_to, :actor, description: "Who the event is attributed to (often a group)")
    # field(:tags, list_of(:tag))
    field(:category, :category, description: "The event's category")

    field(:participants, list_of(:participant),
      resolve: &Resolvers.Event.list_participants_for_event/3,
      description: "The event's participants"
    )

    # field(:tracks, list_of(:track))
    # field(:sessions, list_of(:session))

    field(:updated_at, :datetime, description: "When the event was last updated")
    field(:created_at, :datetime, description: "When the event was created")
  end
end
