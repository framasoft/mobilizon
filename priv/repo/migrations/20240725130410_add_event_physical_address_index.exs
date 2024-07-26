defmodule Mobilizon.Storage.Repo.Migrations.AddEventPhysicalAddressIndex do
  use Ecto.Migration

  def up do
    create(index("events", [:physical_address_id], name: :events_phys_addr_id))
  end

  def down do
    drop(index("events", [:physical_address_id], name: :events_phys_addr_id))
  end
end
