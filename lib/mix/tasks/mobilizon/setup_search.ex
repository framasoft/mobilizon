defmodule Mix.Tasks.Mobilizon.SetupSearch do
  @moduledoc """
  Temporary task to insert search data from existing events

  This task will be removed in version 1.0.0-beta.3
  """

  use Mix.Task

  import Ecto.Query

  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Workers
  alias Mobilizon.Storage.Repo

  require Logger

  @shortdoc "Insert search data"
  def run([]) do
    Mix.Task.run("app.start")

    events =
      Event
      |> preload([e], :tags)
      |> Repo.all()

    nb_events = length(events)

    IO.puts("\nStarting setting up search for #{nb_events} events, this can take a while…\n")
    insert_search_event(events, nb_events)
  end

  defp insert_search_event([%Event{url: url} = event | events], nb_events) do
    case Workers.BuildSearch.insert_search_event(event) do
      {:ok, _} ->
        Logger.debug("Added event #{url} to the search")

      {:error, res} ->
        Logger.error("Error while adding event #{url} to the search: #{inspect(res)}")
    end

    ProgressBar.render(nb_events - length(events), nb_events)

    insert_search_event(events, nb_events)
  end

  defp insert_search_event([], nb_events) do
    IO.puts("\nFinished setting up search for #{nb_events} events!\n")
  end
end
