defmodule Mobilizon.Storage.Repo.Migrations.AddAddressToActors do
  use Ecto.Migration

  def change do
    alter table(:actors) do
      add(:physical_address_id, references(:addresses, on_delete: :nothing))
    end
  end
end
