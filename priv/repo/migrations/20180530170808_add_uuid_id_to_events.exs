defmodule Mobilizon.Repo.Migrations.AddUUIDIdToEvents do
  use Ecto.Migration

  def up do
    alter table(:events) do
      add(:uuid, :uuid)
    end
  end

  def down do
    alter table(:events) do
      remove(:uuid)
    end
  end
end
