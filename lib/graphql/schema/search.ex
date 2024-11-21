defmodule Mobilizon.GraphQL.Schema.SearchType do
  @moduledoc """
  Schema representation for Search
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.GraphQL.Resolvers.Search
  alias Mobilizon.Service.GlobalSearch.{EventResult, GroupResult}

  interface :event_search_result do
    meta(:authorize, :all)
    field(:id, :id, description: "Internal ID for this event")
    field(:uuid, :uuid, description: "The Event UUID")
    field(:url, :string, description: "The ActivityPub Event URL")
    field(:title, :string, description: "The event's title")
    field(:begins_on, :datetime, description: "Datetime for when the event begins")
    field(:ends_on, :datetime, description: "Datetime for when the event ends")

    field(:long_event, :boolean,
      description: "Whether the event is a long event (activity) or not"
    )

    field(:status, :event_status, description: "Status of the event")
    field(:picture, :media, description: "The event's picture")
    field(:physical_address, :address, description: "The event's physical address")
    field(:attributed_to, :actor, description: "Who the event is attributed to (often a group)")
    field(:organizer_actor, :actor, description: "The event's organizer (as a person)")
    field(:tags, list_of(:tag), description: "The event's tags")
    field(:category, :event_category, description: "The event's category")
    field(:options, :event_options, description: "The event options")

    field(:participant_stats, :participant_stats,
      description: "Statistics on the event's participants"
    )

    resolve_type(fn
      %Event{}, _ ->
        :event

      %EventResult{}, _ ->
        :event_result

      _, _ ->
        nil
    end)
  end

  @desc "Search event result"
  object :event_result do
    meta(:authorize, :all)
    interfaces([:event_search_result])
    field(:id, :id, description: "Internal ID for this event")
    field(:uuid, :uuid, description: "The Event UUID")
    field(:url, :string, description: "The ActivityPub Event URL")
    field(:title, :string, description: "The event's title")
    field(:begins_on, :datetime, description: "Datetime for when the event begins")
    field(:ends_on, :datetime, description: "Datetime for when the event ends")

    field(:long_event, :boolean,
      description: "Whether the event is a long event (activity) or not"
    )

    field(:status, :event_status, description: "Status of the event")
    field(:picture, :media, description: "The event's picture")
    field(:physical_address, :address, description: "The event's physical address")
    field(:attributed_to, :actor, description: "Who the event is attributed to (often a group)")
    field(:organizer_actor, :actor, description: "The event's organizer (as a person)")
    field(:tags, list_of(:tag), description: "The event's tags")
    field(:category, :event_category, description: "The event's category")
    field(:options, :event_options, description: "The event options")

    field(:participant_stats, :participant_stats,
      description: "Statistics on the event's participants"
    )
  end

  interface :group_search_result do
    meta(:authorize, :all)
    field(:id, :id, description: "Internal ID for this group")
    field(:url, :string, description: "The ActivityPub actor's URL")
    field(:type, :actor_type, description: "The type of Actor (Person, Group,…)")
    field(:name, :string, description: "The actor's displayed name")
    field(:domain, :string, description: "The actor's domain if (null if it's this instance)")
    field(:summary, :string, description: "The actor's summary")
    field(:preferred_username, :string, description: "The actor's preferred username")
    field(:avatar, :media, description: "The actor's avatar media")
    field(:banner, :media, description: "The actor's banner media")
    field(:followers_count, :integer, description: "Number of followers for this actor")
    field(:members_count, :integer, description: "Number of followers for this actor")
    field(:physical_address, :address, description: "The type of the event's address")

    resolve_type(fn
      %Actor{type: :Group}, _ ->
        :group

      %GroupResult{}, _ ->
        :group_result

      _, _ ->
        nil
    end)
  end

  @desc "Search group result"
  object :group_result do
    meta(:authorize, :all)
    interfaces([:group_search_result])
    field(:id, :id, description: "Internal ID for this group")
    field(:url, :string, description: "The ActivityPub actor's URL")
    field(:type, :actor_type, description: "The type of Actor (Person, Group,…)")
    field(:name, :string, description: "The actor's displayed name")
    field(:domain, :string, description: "The actor's domain if (null if it's this instance)")
    field(:summary, :string, description: "The actor's summary")
    field(:preferred_username, :string, description: "The actor's preferred username")
    field(:avatar, :media, description: "The actor's avatar media")
    field(:banner, :media, description: "The actor's banner media")
    field(:followers_count, :integer, description: "Number of followers for this actor")
    field(:members_count, :integer, description: "Number of followers for this actor")
    field(:physical_address, :address, description: "The type of the event's address")
  end

  @desc "Search persons result"
  object :persons do
    meta(:authorize, [:administrator, :moderator])
    field(:total, non_null(:integer), description: "Total elements")
    field(:elements, non_null(list_of(:person)), description: "Person elements")
  end

  @desc "Search groups result"
  object :groups do
    meta(:authorize, :all)
    field(:total, non_null(:integer), description: "Total elements")
    field(:elements, non_null(list_of(:group_search_result)), description: "Group elements")
  end

  @desc "Search events result"
  object :events do
    meta(:authorize, :all)
    field(:total, non_null(:integer), description: "Total elements")
    field(:elements, non_null(list_of(:event_search_result)), description: "Event elements")
  end

  @desc """
  A entity that can be interacted with from a remote instance
  """
  interface :interactable do
    field(:url, :string, description: "A public URL for the entity")

    resolve_type(fn
      %Actor{type: :Group}, _ ->
        :group

      %Event{}, _ ->
        :event

      _, _ ->
        nil
    end)
  end

  enum :event_type do
    value(:in_person,
      description:
        "The event will happen in person. It can also be livestreamed, but has a physical address"
    )

    value(:online, description: "The event will only happen online. It has no physical address")
  end

  enum :search_target do
    value(:self, description: "Search only on content from this instance")

    value(:internal,
      description: "Search on content from this instance and from the followed instances"
    )

    value(:global, description: "Search using the global fediverse search")
  end

  enum :search_group_sort_options do
    value(:match_desc, description: "The pertinence of the result")
    value(:member_count_asc, description: "The members count of the group ascendant order")
    value(:member_count_desc, description: "The members count of the group descendent order")
    value(:created_at_asc, description: "When the group was created ascendant order")
    value(:created_at_desc, description: "When the group was created descendent order")
    value(:last_event_activity, description: "Last event activity of the group")
  end

  enum :search_event_sort_options do
    value(:match_desc, description: "The pertinence of the result")
    value(:start_time_asc, description: "The start date of the result, ordered ascending")
    value(:start_time_desc, description: "The start date of the result, ordered descending")
    value(:created_at_desc, description: "When the event was published")
    value(:created_at_asc, description: "When the event was published")
    value(:participant_count_desc, description: "With the most participants")
  end

  object :search_queries do
    @desc "Search persons"
    field :search_persons, :persons do
      arg(:term, :string, default_value: "", description: "Search term")
      arg(:page, :integer, default_value: 1, description: "Result page")
      arg(:limit, :integer, default_value: 10, description: "Results limit per page")
      middleware(Rajska.QueryAuthorization, permit: [:administrator, :moderator], scope: false)
      resolve(&Search.search_persons/3)
    end

    @desc "Search groups"
    field :search_groups, :groups do
      arg(:term, :string, default_value: "", description: "Search term")
      arg(:location, :string, description: "A geohash for coordinates")

      arg(:exclude_my_groups, :boolean,
        description: "Whether to include the groups the current actor is member or follower"
      )

      arg(:minimum_visibility, :group_visibility,
        description: "The minimum visibility the group must have"
      )

      arg(:radius, :float,
        default_value: 50,
        description: "Radius around the location to search in"
      )

      arg(:language_one_of, list_of(:string),
        description: "The list of languages this event can be in"
      )

      arg(:boost_languages, list_of(:string),
        description: "The user's languages that can benefit from a boost in search results"
      )

      arg(:search_target, :search_target,
        default_value: :internal,
        description: "The target of the search (internal or global)"
      )

      arg(:bbox, :string, description: "The bbox to search groups into")
      arg(:zoom, :integer, description: "The zoom level for searching groups")

      arg(:page, :integer, default_value: 1, description: "Result page")
      arg(:limit, :integer, default_value: 10, description: "Results limit per page")

      arg(:sort_by, :search_group_sort_options,
        default_value: :match_desc,
        description: "How to sort search results"
      )

      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Search.search_groups/3)
    end

    @desc "Search events"
    field :search_events, :events do
      arg(:term, :string, default_value: "")
      arg(:tags, :string, description: "A comma-separated string listing the tags")
      arg(:location, :string, description: "A geohash for coordinates")
      arg(:type, :event_type, description: "Whether the event is online or in person")
      arg(:category, :string, description: "The category for the event")

      arg(:category_one_of, list_of(:string),
        description: "The list of categories the event can be in"
      )

      arg(:status_one_of, list_of(:event_status),
        description: "The list of statuses this event can have"
      )

      arg(:language_one_of, list_of(:string),
        description: "The list of languages this event can be in"
      )

      arg(:boost_languages, list_of(:string),
        description: "The user's languages that can benefit from a boost in search results"
      )

      arg(:search_target, :search_target,
        default_value: :internal,
        description: "The target of the search (internal or global)"
      )

      arg(:radius, :float,
        default_value: 50,
        description: "Radius around the location to search in"
      )

      arg(:longevents, :boolean, description: "if mention filter in or out long events")

      arg(:bbox, :string, description: "The bbox to search events into")
      arg(:zoom, :integer, description: "The zoom level for searching events")

      arg(:page, :integer, default_value: 1, description: "Result page")
      arg(:limit, :integer, default_value: 10, description: "Results limit per page")
      arg(:begins_on, :datetime, description: "Filter events by their start date")
      arg(:ends_on, :datetime, description: "Filter events by their end date")

      arg(:sort_by, :search_event_sort_options,
        default_value: :match_desc,
        description: "How to sort search results"
      )

      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Search.search_events/3)
    end

    @desc "Interact with an URI"
    field :interact, :interactable do
      arg(:uri, non_null(:string), description: "The URI for to interact with")
      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Search.interact/3)
    end
  end
end
