defmodule MobilizonWeb.SearchController do
  @moduledoc """
  Controller for Search
  """
  use MobilizonWeb, :controller

  alias Mobilizon.Events
  alias Mobilizon.Actors

  action_fallback(MobilizonWeb.FallbackController)

  def search(conn, %{"name" => name}) do
    events = Events.find_events_by_name(name)
    # find already saved accounts
    case Actors.search(name) do
      {:ok, actors} ->
        render(conn, "search.json", events: events, actors: actors)

      {:error, err} ->
        json(conn, err)
    end
  end
end
