defmodule Mobilizon.Service.Search do
  @moduledoc """
  Module to handle search service
  """

  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Repo
  alias Ecto.Adapters.SQL

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

  def update_search_event(%Event{} = event) do
    SQL.query(
      Repo,
      """
        UPDATE event_search
          SET document =
            (SELECT
              setweight(to_tsvector(unaccent($2)), 'A') ||
              setweight(to_tsvector(unaccent(coalesce($4, ' '))), 'B') ||
              setweight(to_tsvector(unaccent($3)), 'C')
            ),
          title = $2
          WHERE id = $1;
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
