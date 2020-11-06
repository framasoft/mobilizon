defmodule Mobilizon.GraphQL.Resolvers.Search do
  @moduledoc """
  Handles the event-related GraphQL calls
  """

  alias Mobilizon.GraphQL.API.Search

  @doc """
  Search persons
  """
  def search_persons(_parent, %{page: page, limit: limit} = args, _resolution) do
    Search.search_actors(args, page, limit, :Person)
  end

  @doc """
  Search groups
  """
  def search_groups(_parent, %{page: page, limit: limit} = args, _resolution) do
    Search.search_actors(args, page, limit, :Group)
  end

  @doc """
  Search events
  """
  def search_events(_parent, %{page: page, limit: limit} = args, _resolution) do
    Search.search_events(args, page, limit)
  end

  def interact(_parent, %{uri: uri}, _resolution) do
    Search.interact(uri)
  end
end
