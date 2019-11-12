defmodule Mobilizon.Storage.Repo.Migrations.RemoveFloorFromAddresses do
  use Ecto.Migration

  def up do
    alter table(:addresses) do
      remove(:floor)
    end
  end

  def down do
    alter table(:addresses) do
      add(:floor, :string)
    end
  end
end
