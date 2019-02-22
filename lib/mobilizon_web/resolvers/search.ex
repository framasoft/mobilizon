defmodule MobilizonWeb.Resolvers.Search do
  @moduledoc """
  Handles the event-related GraphQL calls
  """
  alias MobilizonWeb.API.Search

  @doc """
  Search events and actors by title
  """
  def search_events_and_actors(_parent, %{search: search, page: page, limit: limit}, _resolution) do
    Search.search(search, page, limit)
  end
end
