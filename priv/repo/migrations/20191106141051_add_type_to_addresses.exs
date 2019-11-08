defmodule Mobilizon.Storage.Repo.Migrations.AddTypeToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add(:type, :string)
    end
  end
end
