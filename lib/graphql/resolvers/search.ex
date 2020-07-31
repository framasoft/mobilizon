defmodule Mobilizon.GraphQL.Resolvers.Search do
  @moduledoc """
  Handles the event-related GraphQL calls
  """

  alias Mobilizon.GraphQL.API.Search

  @doc """
  Search persons
  """
  def search_persons(_parent, %{search: search, page: page, limit: limit}, _resolution) do
    Search.search_actors(search, page, limit, :Person)
  end

  @doc """
  Search groups
  """
  def search_groups(_parent, %{search: search, page: page, limit: limit}, _resolution) do
    Search.search_actors(search, page, limit, :Group)
  end

  @doc """
  Search events
  """
  def search_events(_parent, %{page: page, limit: limit} = args, _resolution) do
    Search.search_events(args, page, limit)
  end
end
