defmodule Mobilizon.Storage.Repo.Migrations.AddProviderToUserAndMakePasswordMandatory do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add(:provider, :string, null: true)
      modify(:password_hash, :string, null: true)
    end
  end

  def down do
    alter table(:users) do
      remove(:provider)
      modify(:password_hash, :string, null: false)
    end
  end
end
