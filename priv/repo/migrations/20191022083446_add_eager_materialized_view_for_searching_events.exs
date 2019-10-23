defmodule Mobilizon.Storage.Repo.Migrations.AddEagerMaterializedViewForSearchingEvents do
  use Ecto.Migration
  import Ecto.Query

  alias Mobilizon.Storage.Repo
  alias Mobilizon.Service.Search
  alias Mobilizon.Events.Event

  require Logger

  def up do
    create table(:event_search, primary_key: false) do
      add(:id, references(:events, on_delete: :delete_all, on_update: :update_all),
        primary_key: true
      )

      add(:title, :text, null: false)
      add(:document, :tsvector)
    end

    # to support full-text searches
    create(index("event_search", [:document], using: :gin))

    # to support substring title matches with ILIKE
    execute(
      "CREATE INDEX event_search_title_trgm_index ON event_search USING gin (title gin_trgm_ops)"
    )

    # to support updating CONCURRENTLY
    create(unique_index("event_search", [:id]))

    flush()

    events =
      Event
      |> preload([e], :tags)
      |> Repo.all()

    nb_events = length(events)

    IO.puts("\nStarting setting up search for #{nb_events} events, this can take a while…\n")
    insert_search_event(events, nb_events)
  end

  defp insert_search_event([%Event{url: url} = event | events], nb_events) do
    with {:ok, _} <- Search.insert_search_event(event) do
      Logger.debug("Added event #{url} to the search")
    else
      {:error, res} ->
        Logger.error("Error while adding event #{url} to the search: #{inspect(res)}")
    end

    ProgressBar.render(nb_events - length(events), nb_events)

    insert_search_event(events, nb_events)
  end

  defp insert_search_event([], nb_events) do
    IO.puts("\nFinished setting up search for #{nb_events} events!\n")
  end

  def down do
    drop(table(:event_search))
  end
end
