defmodule Mobilizon.GraphQL.Schema.SearchType do
  @moduledoc """
  Schema representation for Search
  """
  use Absinthe.Schema.Notation

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

  object :search_queries do
    @desc "Search persons"
    field :search_persons, :persons do
      arg(:search, non_null(:string))
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)

      resolve(&Search.search_persons/3)
    end

    @desc "Search groups"
    field :search_groups, :groups do
      arg(:search, non_null(:string))
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)

      resolve(&Search.search_groups/3)
    end

    @desc "Search events"
    field :search_events, :events do
      arg(:term, :string, default_value: "")
      arg(:tag, :string)
      arg(:location, :string, description: "A geohash for coordinates")
      arg(:radius, :float, default_value: 50)
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)

      resolve(&Search.search_events/3)
    end
  end
end
