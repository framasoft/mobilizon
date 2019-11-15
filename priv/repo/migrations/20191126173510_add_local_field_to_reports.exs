defmodule Mobilizon.Storage.Repo.Migrations.AddLocalFieldToReports do
  use Ecto.Migration

  def up do
    alter table(:reports) do
      add(:local, :boolean, default: true, null: false)
    end

    rename(table(:reports), :uri, to: :url)
  end

  def down do
    alter table(:reports) do
      remove(:local)
    end

    rename(table(:reports), :url, to: :uri)
  end
end
