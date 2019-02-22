defmodule Mobilizon.Repo.Migrations.AddUUIDToComments do
  use Ecto.Migration

  def up do
    alter table(:comments) do
      add(:uuid, :uuid)
    end
  end

  def down do
    alter table(:comments) do
      remove(:uuid)
    end
  end
end
