defmodule Mobilizon.Repo.Migrations.AddAddressType do
  use Ecto.Migration

  def up do
    alter table(:events) do
      add(:online_address, :string)
      add(:phone, :string)
    end

    drop(constraint(:events, "events_address_id_fkey"))
    rename(table(:events), :address_id, to: :physical_address_id)

    alter table(:events) do
      modify(:physical_address_id, references(:addresses, on_delete: :nothing))
    end
  end

  def down do
    alter table(:events) do
      remove(:online_address)
      remove(:phone)
    end

    drop(constraint(:events, "events_physical_address_id_fkey"))
    rename(table(:events), :physical_address_id, to: :address_id)

    alter table(:events) do
      modify(:address_id, references(:addresses, on_delete: :nothing))
    end
  end
end
