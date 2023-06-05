defmodule Mobilizon.Storage.Repo.Migrations.RemoveObsoleteEventIdOnReports do
  use Ecto.Migration

  def up do
    alter table(:reports) do
      remove_if_exists :event_id, :integer
    end
  end

  def down do
    alter table(:reports) do
      add(:event_id, references(:events, on_delete: :delete_all), null: true)
    end
  end
end
