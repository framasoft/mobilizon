defmodule MobilizonWeb.Schema.EventType do
  @moduledoc """
  Schema representation for Event
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.{Actors, Addresses}
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import_types(MobilizonWeb.Schema.AddressType)
  import_types(MobilizonWeb.Schema.Events.ParticipantType)
  import_types(MobilizonWeb.Schema.TagType)
  alias MobilizonWeb.Resolvers.{Picture, Event, Tag}

  @desc "An event"
  object :event do
    interfaces([:action_log_object])
    field(:id, :id, description: "Internal ID for this event")
    field(:uuid, :uuid, description: "The Event UUID")
    field(:url, :string, description: "The ActivityPub Event URL")
    field(:local, :boolean, description: "Whether the event is local or not")
    field(:title, :string, description: "The event's title")
    field(:slug, :string, description: "The event's description's slug")
    field(:description, :string, description: "The event's description")
    field(:begins_on, :datetime, description: "Datetime for when the event begins")
    field(:ends_on, :datetime, description: "Datetime for when the event ends")
    field(:status, :event_status, description: "Status of the event")
    field(:visibility, :event_visibility, description: "The event's visibility")
    field(:join_options, :event_join_options, description: "The event's visibility")

    field(:picture, :picture,
      description: "The event's picture",
      resolve: &Picture.picture/3
    )

    field(:publish_at, :datetime, description: "When the event was published")

    field(:physical_address, :address,
      resolve: dataloader(Addresses),
      description: "The type of the event's address"
    )

    field(:online_address, :string, description: "Online address of the event")
    field(:phone_address, :string, description: "Phone address for the event")

    field(:organizer_actor, :actor,
      resolve: dataloader(Actors),
      description: "The event's organizer (as a person)"
    )

    field(:attributed_to, :actor, description: "Who the event is attributed to (often a group)")

    field(:tags, list_of(:tag),
      resolve: &Tag.list_tags_for_event/3,
      description: "The event's tags"
    )

    field(:category, :string, description: "The event's category")

    field(:participant_stats, :participant_stats, resolve: &Event.stats_participants_for_event/3)

    field(:participants, list_of(:participant), description: "The event's participants") do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      arg(:roles, :string, default_value: "")
      resolve(&Event.list_participants_for_event/3)
    end

    field(:related_events, list_of(:event),
      resolve: &Event.list_related_events/3,
      description: "Events related to this one"
    )

    # field(:tracks, list_of(:track))
    # field(:sessions, list_of(:session))

    field(:updated_at, :datetime, description: "When the event was last updated")
    field(:created_at, :datetime, description: "When the event was created")
    field(:options, :event_options, description: "The event options")
  end

  @desc "The list of visibility options for an event"
  enum :event_visibility do
    value(:public, description: "Publicly listed and federated. Can be shared.")
    value(:unlisted, description: "Visible only to people with the link - or invited")
    value(:restricted, description: "Visible only after a moderator accepted")

    value(:private,
      description: "Visible only to people members of the group or followers of the person"
    )
  end

  @desc "The list of join options for an event"
  enum :event_join_options do
    value(:free, description: "Anyone can join and is automatically accepted")
    value(:restricted, description: "Manual acceptation")
    value(:invite, description: "Participants must be invited")
  end

  @desc "The list of possible options for the event's status"
  enum :event_status do
    value(:tentative, description: "The event is tentative")
    value(:confirmed, description: "The event is confirmed")
    value(:cancelled, description: "The event is cancelled")
  end

  object :participant_stats do
    field(:approved, :integer, description: "The number of approved participants")
    field(:unapproved, :integer, description: "The number of unapproved participants")
  end

  object :event_offer do
    field(:price, :float, description: "The price amount for this offer")
    field(:price_currency, :string, description: "The currency for this price offer")
    field(:url, :string, description: "The URL to access to this offer")
  end

  object :event_participation_condition do
    field(:title, :string, description: "The title for this condition")
    field(:content, :string, description: "The content for this condition")
    field(:url, :string, description: "The URL to access this condition")
  end

  input_object :event_offer_input do
    field(:price, :float, description: "The price amount for this offer")
    field(:price_currency, :string, description: "The currency for this price offer")
    field(:url, :string, description: "The URL to access to this offer")
  end

  input_object :event_participation_condition_input do
    field(:title, :string, description: "The title for this condition")
    field(:content, :string, description: "The content for this condition")
    field(:url, :string, description: "The URL to access this condition")
  end

  @desc "The list of possible options for the event's status"
  enum :event_comment_moderation do
    value(:allow_all, description: "Anyone can comment under the event")
    value(:moderated, description: "Every comment has to be moderated by the admin")
    value(:closed, description: "No one can comment except for the admin")
  end

  object :event_options do
    field(:maximum_attendee_capacity, :integer,
      description: "The maximum attendee capacity for this event"
    )

    field(:remaining_attendee_capacity, :integer,
      description: "The number of remaining seats for this event"
    )

    field(:show_remaining_attendee_capacity, :boolean,
      description: "Whether or not to show the number of remaining seats for this event"
    )

    field(:offers, list_of(:event_offer), description: "The list of offers to show for this event")

    field(:participation_conditions, list_of(:event_participation_condition),
      description: "The list of participation conditions to accept to join this event"
    )

    field(:attendees, list_of(:string), description: "The list of special attendees")
    field(:program, :string, description: "The list of the event")

    field(:comment_moderation, :event_comment_moderation,
      description: "The policy on public comment moderation under the event"
    )

    field(:show_participation_price, :boolean,
      description: "Whether or not to show the participation price"
    )
  end

  input_object :event_options_input do
    field(:maximum_attendee_capacity, :integer,
      description: "The maximum attendee capacity for this event"
    )

    field(:remaining_attendee_capacity, :integer,
      description: "The number of remaining seats for this event"
    )

    field(:show_remaining_attendee_capacity, :boolean,
      description: "Whether or not to show the number of remaining seats for this event"
    )

    field(:offers, list_of(:event_offer_input),
      description: "The list of offers to show for this event"
    )

    field(:participation_conditions, list_of(:event_participation_condition_input),
      description: "The list of participation conditions to accept to join this event"
    )

    field(:attendees, list_of(:string), description: "The list of special attendees")
    field(:program, :string, description: "The list of the event")

    field(:comment_moderation, :event_comment_moderation,
      description: "The policy on public comment moderation under the event"
    )

    field(:show_participation_price, :boolean,
      description: "Whether or not to show the participation price"
    )
  end

  object :event_queries do
    @desc "Get all events"
    field :events, list_of(:event) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Event.list_events/3)
    end

    @desc "Get an event by uuid"
    field :event, :event do
      arg(:uuid, non_null(:uuid))
      resolve(&Event.find_event/3)
    end
  end

  object :event_mutations do
    @desc "Create an event"
    field :create_event, type: :event do
      arg(:title, non_null(:string))
      arg(:description, non_null(:string))
      arg(:begins_on, non_null(:datetime))
      arg(:ends_on, :datetime)
      arg(:status, :event_status)
      arg(:visibility, :event_visibility, default_value: :private)
      arg(:join_options, :event_join_options, default_value: :free)

      arg(:tags, list_of(:string),
        default_value: [],
        description: "The list of tags associated to the event"
      )

      arg(:picture, :picture_input,
        description:
          "The picture for the event, either as an object or directly the ID of an existing Picture"
      )

      arg(:publish_at, :datetime)
      arg(:online_address, :string)
      arg(:phone_address, :string)
      arg(:organizer_actor_id, non_null(:id))
      arg(:category, :string, default_value: "meeting")
      arg(:physical_address, :address_input)
      arg(:options, :event_options_input)

      resolve(&Event.create_event/3)
    end

    @desc "Update an event"
    field :update_event, type: :event do
      arg(:event_id, non_null(:id))

      arg(:title, :string)
      arg(:description, :string)
      arg(:begins_on, :datetime)
      arg(:ends_on, :datetime)
      arg(:status, :event_status)
      arg(:visibility, :event_visibility)
      arg(:join_options, :event_join_options)

      arg(:tags, list_of(:string), description: "The list of tags associated to the event")

      arg(:picture, :picture_input,
        description:
          "The picture for the event, either as an object or directly the ID of an existing Picture"
      )

      arg(:online_address, :string)
      arg(:phone_address, :string)
      arg(:category, :string)
      arg(:physical_address, :address_input)
      arg(:options, :event_options_input)

      resolve(&Event.update_event/3)
    end

    @desc "Delete an event"
    field :delete_event, :deleted_object do
      arg(:event_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Event.delete_event/3)
    end
  end
end
