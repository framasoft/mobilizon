defmodule Mobilizon.Storage.Repo.Migrations.AddIndexesToAddresses do
  use Ecto.Migration

  def up do
    create_if_not_exists(index("addresses", ["st_x(geom)"], name: "idx_addresses_geom_x"))
    create_if_not_exists(index("addresses", ["st_y(geom)"], name: "idx_addresses_geom_y"))
  end

  def down do
    drop_if_exists(index("addresses", ["st_x(geom)"], name: "idx_addresses_geom_x"))
    drop_if_exists(index("addresses", ["st_y(geom)"], name: "idx_addresses_geom_y"))
  end
end
