defmodule Mobilizon.Storage.Repo.Migrations.AllowMultipleEventsToBeReported do
  use Ecto.Migration

  def up do
    create table(:reports_events, primary_key: false) do
      add(:report_id, references(:reports, on_delete: :delete_all), null: false)
      add(:event_id, references(:events, on_delete: :delete_all), null: false)
    end
  end

  def down do
    drop table(:reports_events)
  end
end
