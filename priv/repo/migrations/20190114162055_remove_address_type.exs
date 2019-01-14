defmodule Mobilizon.Repo.Migrations.RemoveAddressType do
  use Ecto.Migration

  def up do
    alter table(:events) do
      remove(:address_type)
    end
    execute "DROP TYPE address_type"
    rename table(:events), :phone, to: :phone_address
  end
end
