defmodule Mobilizon.Storage.Repo.Migrations.MoveMemberIdToUuid do
  use Ecto.Migration

  def up do
    alter table(:members, primary_key: false) do
      remove(:id)
      add(:id, :uuid, primary_key: true)
      add(:url, :string, null: false)
      add(:metadata, :map)
    end
  end

  def down do
    alter table(:members, primary_key: true) do
      remove(:id)
      remove(:url)
      remove(:metadata)
      add(:id, :serial, primary_key: true)
    end
  end
end
