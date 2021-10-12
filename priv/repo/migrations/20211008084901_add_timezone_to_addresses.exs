defmodule Mobilizon.Storage.Repo.Migrations.AddTimezoneToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add(:timezone, :string)
    end
  end
end
