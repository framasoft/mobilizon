defmodule EventosWeb.SearchController do
  @moduledoc """
  Controller for Search
  """
  use EventosWeb, :controller

  alias Eventos.Events
  alias Eventos.Actors

  action_fallback(EventosWeb.FallbackController)

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
