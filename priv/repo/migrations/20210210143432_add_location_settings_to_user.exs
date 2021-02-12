defmodule Mobilizon.Storage.Repo.Migrations.AddLocationSettingsToUser do
  use Ecto.Migration

  def change do
    alter table(:user_settings) do
      add(:location, :map)
    end
  end
end
