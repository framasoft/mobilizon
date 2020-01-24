defmodule Mobilizon.Service.Workers.BuildSearch do
  @moduledoc """
  Worker to build search results
  """

  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Repo
  alias Ecto.Adapters.SQL

  use Mobilizon.Service.Workers.Helper, queue: "search"

  @impl Oban.Worker
  def perform(%{"op" => "insert_search_event", "event_id" => event_id}, _job) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id) do
      insert_search_event(event)
    end
  end

  def perform(%{"op" => "update_search_event", "event_id" => event_id}, _job) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id) do
      insert_search_event(event)
    end
  end

  def insert_search_event(%Event{} = event) do
    SQL.query(
      Repo,
      """
        INSERT INTO event_search(id, title, document) VALUES ($1, $2, (
          SELECT
            setweight(to_tsvector(unaccent($2)), 'A') ||
            setweight(to_tsvector(unaccent(coalesce($4, ' '))), 'B') ||
            setweight(to_tsvector(unaccent($3)), 'C')
          )
        ) ON CONFLICT (id) DO UPDATE SET title = $2, document = (
          SELECT
            setweight(to_tsvector(unaccent($2)), 'A') ||
            setweight(to_tsvector(unaccent(coalesce($4, ' '))), 'B') ||
            setweight(to_tsvector(unaccent($3)), 'C')
          );
      """,
      [
        event.id,
        event.title,
        HtmlSanitizeEx.strip_tags(event.description),
        get_tags_string(event)
      ]
    )
  end

  defp get_tags_string(%Event{tags: tags}) do
    tags
    |> Enum.map(& &1.title)
    |> Enum.join(" ")
  end
end
