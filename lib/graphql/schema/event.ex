defmodule Mobilizon.GraphQL.Schema.EventType do
  @moduledoc """
  Schema representation for Event.
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1, dataloader: 2]

  alias Mobilizon.{Actors, Addresses, Discussions}
  alias Mobilizon.GraphQL.Resolvers.{Conversation, Event, Media, Tag}
  alias Mobilizon.GraphQL.Schema

  import_types(Schema.AddressType)
  import_types(Schema.Events.ParticipantType)
  import_types(Schema.TagType)

  @env Application.compile_env(:mobilizon, :env)
  @event_rate_limiting 60

  @desc "An event"
  object :event do
    meta(:authorize, :all)
    meta(:scope_field?, true)
    interfaces([:action_log_object, :interactable, :activity_object, :event_search_result])
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
    field(:external_participation_url, :string, description: "External URL for participation")

    field(:picture, :media,
      description: "The event's picture",
      resolve: &Media.media/3
    )

    field(:media, list_of(:media),
      description: "The event's media",
      resolve: &Media.medias/3
    )

    field(:publish_at, :datetime, description: "When the event was published")

    field(:physical_address, :address,
      resolve: dataloader(Addresses),
      description: "The event's physical address"
    )

    field(:online_address, :string, description: "Online address of the event")
    field(:phone_address, :string, description: "Phone address for the event")

    field(:attributed_to, :actor,
      resolve: dataloader(Actors),
      description: "Who the event is attributed to (often a group)"
    )

    field(:organizer_actor, :actor,
      resolve: &Event.organizer_for_event/3,
      description: "The event's organizer (as a person)"
    )

    field(:tags, list_of(:tag), description: "The event's tags") do
      resolve(&Tag.list_tags_for_event/3)
    end

    field(:category, :event_category, description: "The event's category")

    field(:draft, :boolean, description: "Whether or not the event is a draft")

    field(:participant_stats, :participant_stats,
      description: "Statistics on the event",
      resolve: &Event.stats_participants/3
    )

    field(:participants, :paginated_participant_list,
      description: "The event's participants",
      meta: [private: true, rule: :"read:event:participants"]
    ) do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated participants list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of participants per page")
      arg(:roles, :string, default_value: "", description: "Filter by roles")
      resolve(&Event.list_participants_for_event/3)
    end

    field(:contacts, list_of(:actor), description: "The events contacts")

    field(:related_events, list_of(:event),
      resolve: &Event.list_related_events/3,
      description: "Events related to this one"
    )

    field(:comments, list_of(:comment), description: "The comments in reply to the event") do
      resolve(dataloader(Discussions, args: %{top_level: true}))
    end

    # field(:tracks, list_of(:track))
    # field(:sessions, list_of(:session))

    field(:updated_at, :datetime, description: "When the event was last updated")
    field(:inserted_at, :datetime, description: "When the event was created")
    field(:options, :event_options, description: "The event options")
    field(:metadata, list_of(:event_metadata), description: "A key-value list of metadata")
    field(:language, :string, description: "The event language")

    field(:conversations, :paginated_conversation_list,
      description: "The list of conversations started on this event"
    ) do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated conversation list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of conversations per page")
      resolve(&Conversation.find_conversations_for_event/3)
    end
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
    value(:external, description: "External registration")
  end

  @desc "The list of possible options for the event's status"
  enum :event_status do
    value(:tentative, description: "The event is tentative")
    value(:confirmed, description: "The event is confirmed")
    value(:cancelled, description: "The event is cancelled")
  end

  @desc "A paginated list of events"
  object :paginated_event_list do
    meta(:authorize, :all)
    field(:elements, list_of(:event), description: "A list of events")
    field(:total, :integer, description: "The total number of events in the list")
  end

  @desc "Participation statistics"
  object :participant_stats do
    meta(:authorize, :all)
    field(:going, :integer, description: "The number of approved participants")
    field(:not_approved, :integer, description: "The number of not approved participants")
    field(:not_confirmed, :integer, description: "The number of not confirmed participants")
    field(:rejected, :integer, description: "The number of rejected participants")

    field(:participant, :integer,
      description: "The number of simple participants (excluding creators)"
    )

    field(:moderator, :integer, description: "The number of moderators")
    field(:administrator, :integer, description: "The number of administrators")
    field(:creator, :integer, description: "The number of creators")
  end

  @desc """
  An event offer
  """
  object :event_offer do
    meta(:authorize, :all)
    field(:price, :float, description: "The price amount for this offer")
    field(:price_currency, :string, description: "The currency for this price offer")
    field(:url, :string, description: "The URL to access to this offer")
  end

  @desc """
  An event participation condition
  """
  object :event_participation_condition do
    meta(:authorize, :all)
    field(:title, :string, description: "The title for this condition")
    field(:content, :string, description: "The content for this condition")
    field(:url, :string, description: "The URL to access this condition")
  end

  @desc """
  An event offer
  """
  input_object :event_offer_input do
    field(:price, :float, description: "The price amount for this offer")
    field(:price_currency, :string, description: "The currency for this price offer")
    field(:url, :string, description: "The URL to access to this offer")
  end

  @desc """
  An event participation condition
  """
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

  @desc """
  Event options
  """
  object :event_options do
    meta(:authorize, :all)

    field(:maximum_attendee_capacity, :integer,
      description: "The maximum attendee capacity for this event"
    )

    field(:remaining_attendee_capacity, :integer,
      description: "The number of remaining seats for this event"
    )

    field(:show_remaining_attendee_capacity, :boolean,
      description: "Whether or not to show the number of remaining seats for this event"
    )

    field(:anonymous_participation, :boolean,
      description: "Whether or not to allow anonymous participation (if the server allows it)"
    )

    field(:offers, list_of(:event_offer),
      description: "The list of offers to show for this event"
    )

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

    field(:hide_number_of_participants, :boolean,
      description: "Whether or not the number of participants is hidden"
    )

    field(:show_start_time, :boolean, description: "Show event start time")
    field(:show_end_time, :boolean, description: "Show event end time")

    field(:timezone, :timezone, description: "The event's timezone")

    field(:hide_organizer_when_group_event, :boolean,
      description:
        "Whether to show or hide the person organizer when event is organized by a group"
    )

    field(:is_online, :boolean, description: "Whether the event is fully online")
  end

  @desc """
  Event options
  """
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

    field(:anonymous_participation, :boolean,
      default_value: false,
      description: "Whether or not to allow anonymous participation (if the server allows it)"
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

    field(:hide_number_of_participants, :boolean,
      description: "Whether or not the number of participants is hidden"
    )

    field(:show_start_time, :boolean, description: "Show event start time")
    field(:show_end_time, :boolean, description: "Show event end time")

    field(:timezone, :timezone, description: "The event's timezone")

    field(:hide_organizer_when_group_event, :boolean,
      description:
        "Whether to show or hide the person organizer when event is organized by a group"
    )

    field(:is_online, :boolean, description: "Whether the event is fully online")
  end

  enum :event_metadata_type do
    value(:string, description: "A string")
    value(:integer, description: "An integer")
    value(:boolean, description: "A boolean")
  end

  object :event_metadata do
    meta(:authorize, :all)
    field(:key, :string, description: "The key for the metadata")
    field(:title, :string, description: "The title for the metadata")
    field(:value, :string, description: "The value for the metadata")
    field(:type, :event_metadata_type, description: "The metadata type")
  end

  input_object :event_metadata_input do
    field(:key, non_null(:string), description: "The key for the metadata")
    field(:title, :string, description: "The title for the metadata")
    field(:value, non_null(:string), description: "The value for the metadata")
    field(:type, :event_metadata_type, description: "The metadata type")
  end

  @desc """
  A event contact
  """
  input_object :contact do
    field(:id, :string, description: "The Contact Actor ID")
  end

  @desc "Available event sort fields"
  enum :event_order_by do
    value(:begins_on, description: "Sort by the date the event starts")
    value(:inserted_at, description: "Sort by the date the event was created")
    value(:updated_at, description: "Sort by the date the event was updated")
  end

  object :event_queries do
    @desc "Get all events"
    field :events, :paginated_event_list do
      arg(:location, :string, default_value: nil, description: "A geohash for coordinates")

      arg(:radius, :float,
        default_value: nil,
        description: "Radius around the location to search in"
      )

      arg(:page, :integer, default_value: 1, description: "The page in the paginated event list")
      arg(:limit, :integer, default_value: 10, description: "The limit of events per page")

      arg(:order_by, :event_order_by,
        default_value: :begins_on,
        description: "Order the list of events by field"
      )

      arg(:direction, :sort_direction,
        default_value: :asc,
        description: "Direction for the sort"
      )

      arg(:longevents, :boolean,
        default_value: nil,
        description: "if mention filter in or out long events"
      )

      middleware(Rajska.QueryAuthorization, permit: :all)

      resolve(&Event.list_events/3)
    end

    @desc "Get an event by uuid"
    field :event, :event do
      arg(:uuid, non_null(:uuid), description: "The event's UUID")
      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Event.find_event/3)
    end
  end

  object :event_mutations do
    @desc "Create an event"
    field :create_event, type: :event do
      arg(:title, non_null(:string), description: "The event's title")
      arg(:description, non_null(:string), description: "The event's description")
      arg(:begins_on, non_null(:datetime), description: "Datetime for when the event begins")
      arg(:ends_on, :datetime, description: "Datetime for when the event ends")
      arg(:status, :event_status, description: "Status of the event")

      arg(:visibility, :event_visibility,
        default_value: :public,
        description: "The event's visibility"
      )

      arg(:join_options, :event_join_options,
        default_value: :free,
        description: "The event's options to join"
      )

      arg(:external_participation_url, :string, description: "External URL for participation")

      arg(:tags, list_of(:string),
        default_value: [],
        description: "The list of tags associated to the event"
      )

      arg(:picture, :media_input,
        description:
          "The picture for the event, either as an object or directly the ID of an existing media"
      )

      arg(:publish_at, :datetime, description: "Datetime when the event was published")
      arg(:online_address, :string, description: "Online address of the event")
      arg(:phone_address, :string, description: "Phone address for the event")

      arg(:organizer_actor_id, non_null(:id),
        description: "The event's organizer ID (as a person)"
      )

      arg(:attributed_to_id, :id,
        description: "Who the event is attributed to ID (often a group)"
      )

      arg(:category, :event_category,
        default_value: "MEETING",
        description: "The event's category"
      )

      arg(:physical_address, :address_input, description: "The event's physical address")
      arg(:options, :event_options_input, default_value: %{}, description: "The event options")
      arg(:metadata, list_of(:event_metadata_input), description: "The event metadata")

      arg(:draft, :boolean,
        default_value: false,
        description: "Whether or not the event is a draft"
      )

      arg(:contacts, list_of(:contact), default_value: [], description: "The events contacts")
      arg(:language, :string, description: "The event language", default_value: "und")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Events.Event,
        rule: :"write:event:create",
        args: %{organizer_actor_id: :organizer_actor_id}
      )

      middleware(Rajska.RateLimiter, limit: event_rate_limiting(@env))

      resolve(&Event.create_event/3)
    end

    @desc "Update an event"
    field :update_event, type: :event do
      arg(:event_id, non_null(:id), description: "The event's ID")

      arg(:title, :string, description: "The event's title")
      arg(:description, :string, description: "The event's description")
      arg(:begins_on, :datetime, description: "Datetime for when the event begins")
      arg(:ends_on, :datetime, description: "Datetime for when the event ends")
      arg(:status, :event_status, description: "Status of the event")

      arg(:visibility, :event_visibility,
        default_value: :public,
        description: "The event's visibility"
      )

      arg(:join_options, :event_join_options,
        default_value: :free,
        description: "The event's options to join"
      )

      arg(:external_participation_url, :string, description: "External URL for participation")

      arg(:tags, list_of(:string), description: "The list of tags associated to the event")

      arg(:picture, :media_input,
        description:
          "The picture for the event, either as an object or directly the ID of an existing media"
      )

      arg(:online_address, :string, description: "Online address of the event")
      arg(:phone_address, :string, description: "Phone address for the event")
      arg(:organizer_actor_id, :id, description: "The event's organizer ID (as a person)")

      arg(:attributed_to_id, :id,
        description: "Who the event is attributed to ID (often a group)"
      )

      arg(:category, :event_category, description: "The event's category")
      arg(:physical_address, :address_input, description: "The event's physical address")
      arg(:options, :event_options_input, description: "The event options")
      arg(:metadata, list_of(:event_metadata_input), description: "The event metadata")
      arg(:draft, :boolean, description: "Whether or not the event is a draft")
      arg(:contacts, list_of(:contact), default_value: [], description: "The events contacts")
      arg(:language, :string, description: "The event language", default_value: "und")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Events.Event,
        args: %{id: :event_id},
        rule: :"write:event:update"
      )

      resolve(&Event.update_event/3)
    end

    @desc "Delete an event"
    field :delete_event, :deleted_object do
      arg(:event_id, non_null(:id), description: "The event ID to delete")

      middleware(Rajska.QueryAuthorization,
        permit: [:user, :moderator, :administrator],
        scope: Mobilizon.Events.Event,
        rule: :"write:event:delete",
        args: %{id: :event_id}
      )

      resolve(&Event.delete_event/3)
    end
  end

  defp event_rate_limiting(:test), do: @event_rate_limiting * 1000
  defp event_rate_limiting(_), do: @event_rate_limiting
end
