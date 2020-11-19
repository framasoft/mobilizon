defmodule Mobilizon.GraphQL.Schema.SearchType do
  @moduledoc """
  Schema representation for Search
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.GraphQL.Resolvers.Search

  @desc "Search persons result"
  object :persons do
    field(:total, non_null(:integer), description: "Total elements")
    field(:elements, non_null(list_of(:person)), description: "Person elements")
  end

  @desc "Search groups result"
  object :groups do
    field(:total, non_null(:integer), description: "Total elements")
    field(:elements, non_null(list_of(:group)), description: "Group elements")
  end

  @desc "Search events result"
  object :events do
    field(:total, non_null(:integer), description: "Total elements")
    field(:elements, non_null(list_of(:event)), description: "Event elements")
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

  object :search_queries do
    @desc "Search persons"
    field :search_persons, :persons do
      arg(:term, :string, default_value: "", description: "Search term")
      arg(:page, :integer, default_value: 1, description: "Result page")
      arg(:limit, :integer, default_value: 10, description: "Results limit per page")

      resolve(&Search.search_persons/3)
    end

    @desc "Search groups"
    field :search_groups, :groups do
      arg(:term, :string, default_value: "", description: "Search term")
      arg(:location, :string, description: "A geohash for coordinates")

      arg(:radius, :float,
        default_value: 50,
        description: "Radius around the location to search in"
      )

      arg(:page, :integer, default_value: 1, description: "Result page")
      arg(:limit, :integer, default_value: 10, description: "Results limit per page")

      resolve(&Search.search_groups/3)
    end

    @desc "Search events"
    field :search_events, :events do
      arg(:term, :string, default_value: "")
      arg(:tags, :string, description: "A comma-separated string listing the tags")
      arg(:location, :string, description: "A geohash for coordinates")

      arg(:radius, :float,
        default_value: 50,
        description: "Radius around the location to search in"
      )

      arg(:page, :integer, default_value: 1, description: "Result page")
      arg(:limit, :integer, default_value: 10, description: "Results limit per page")
      arg(:begins_on, :datetime, description: "Filter events by their start date")
      arg(:ends_on, :datetime, description: "Filter events by their end date")

      resolve(&Search.search_events/3)
    end

    @desc "Interact with an URI"
    field :interact, :interactable do
      arg(:uri, non_null(:string), description: "The URI for to interact with")

      resolve(&Search.interact/3)
    end
  end
end
