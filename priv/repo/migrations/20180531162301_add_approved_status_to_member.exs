defmodule Mobilizon.Repo.Migrations.AddApprovedStatusToMember do
  use Ecto.Migration

  def up do
    alter table(:members) do
      add(:approved, :boolean, default: true)
    end
  end

  def down do
    alter table(:members) do
      remove(:approved)
    end
  end
end
