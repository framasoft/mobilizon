defmodule Mobilizon.Repo.Migrations.AddOriginIdToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add(:origin_id, :string)
    end

    create(index(:addresses, [:origin_id], unique: true))
  end
end
