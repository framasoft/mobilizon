defmodule Mobilizon.Storage.Repo.Migrations.AddEagerMaterializedViewForSearchingEvents do
  use Ecto.Migration

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
  end

  def down do
    drop(table(:event_search))
  end
end
