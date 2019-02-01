defmodule MobilizonWeb.Schema.EventType do
  @moduledoc """
  Schema representation for Event
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.Actors
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import_types(MobilizonWeb.Schema.AddressType)
  import_types(MobilizonWeb.Schema.Events.ParticipantType)
  import_types(MobilizonWeb.Schema.Events.CategoryType)
  alias MobilizonWeb.Resolvers

  @desc "An event"
  object :event do
    field(:id, :integer, description: "Internal ID for this event")
    field(:uuid, :uuid, description: "The Event UUID")
    field(:url, :string, description: "The ActivityPub Event URL")
    field(:local, :boolean, description: "Whether the event is local or not")
    field(:title, :string, description: "The event's title")
    field(:description, :string, description: "The event's description")
    field(:begins_on, :datetime, description: "Datetime for when the event begins")
    field(:ends_on, :datetime, description: "Datetime for when the event ends")
    field(:status, :event_status, description: "Status of the event")
    field(:visibility, :event_visibility, description: "The event's visibility")
    # TODO replace me with picture object
    field(:thumbnail, :string, description: "A thumbnail picture for the event")
    # TODO replace me with banner
    field(:large_image, :string, description: "A large picture for the event")
    field(:publish_at, :datetime, description: "When the event was published")
    field(:physical_address, :physical_address, description: "The type of the event's address")
    field(:online_address, :online_address, description: "Online address of the event")
    field(:phone_address, :phone_address, description: "Phone address for the event")

    field(:organizer_actor, :actor,
      resolve: dataloader(Actors),
      description: "The event's organizer (as a person)"
    )

    field(:attributed_to, :actor, description: "Who the event is attributed to (often a group)")
    # field(:tags, list_of(:tag))
    field(:category, :category, description: "The event's category")

    field(:participants, list_of(:participant),
      resolve: &MobilizonWeb.Resolvers.Event.list_participants_for_event/3,
      description: "The event's participants"
    )

    # field(:tracks, list_of(:track))
    # field(:sessions, list_of(:session))

    field(:updated_at, :datetime, description: "When the event was last updated")
    field(:created_at, :datetime, description: "When the event was created")
  end

  @desc "The list of visibility options for an event"
  enum :event_visibility do
    value(:public, description: "Publically listed and federated. Can be shared.")
    value(:unlisted, description: "Visible only to people with the link - or invited")

    value(:private,
      description: "Visible only to people members of the group or followers of the person"
    )

    value(:moderated, description: "Visible only after a moderator accepted")
    value(:invite, description: "visible only to people invited")
  end

  @desc "The list of possible options for the event's status"
  enum :event_status do
    value(:tentative, description: "The event is tentative")
    value(:confirmed, description: "The event is confirmed")
    value(:cancelled, description: "The event is cancelled")
  end

  object :event_queries do
    @desc "Get all events"
    field :events, list_of(:event) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Event.list_events/3)
    end

    @desc "Get an event by uuid"
    field :event, :event do
      arg(:uuid, non_null(:uuid))
      resolve(&Resolvers.Event.find_event/3)
    end
  end

  object :event_mutations do
    @desc "Create an event"
    field :create_event, type: :event do
      arg(:title, non_null(:string))
      arg(:description, non_null(:string))
      arg(:begins_on, non_null(:datetime))
      arg(:ends_on, :datetime)
      arg(:state, :integer)
      arg(:status, :integer)
      arg(:public, :boolean)
      arg(:thumbnail, :string)
      arg(:large_image, :string)
      arg(:publish_at, :datetime)
      arg(:online_address, :string)
      arg(:phone_address, :string)
      arg(:organizer_actor_id, non_null(:id))
      arg(:category, non_null(:string))

      resolve(&Resolvers.Event.create_event/3)
    end

    @desc "Delete an event"
    field :delete_event, :deleted_object do
      arg(:event_id, non_null(:integer))
      arg(:actor_id, non_null(:integer))

      resolve(&Resolvers.Event.delete_event/3)
    end
  end
end
