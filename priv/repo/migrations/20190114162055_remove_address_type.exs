defmodule Mobilizon.Repo.Migrations.RemoveAddressType do
  use Ecto.Migration
  require Logger

  def up do
    execute("ALTER TABLE \"events\" DROP COLUMN IF EXISTS address_type")
    execute("DROP TYPE IF EXISTS address_type")
    rename(table(:events), :phone, to: :phone_address)
  end
end
