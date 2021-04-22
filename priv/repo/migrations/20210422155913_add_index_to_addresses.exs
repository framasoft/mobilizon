defmodule Mobilizon.Storage.Repo.Migrations.AddIndexToAddresses do
  use Ecto.Migration

  def up do
    create_if_not_exists(unique_index("addresses", [:url]))
  end

  def down do
    drop_if_exists(index("addresses", [:url]))
  end
end
