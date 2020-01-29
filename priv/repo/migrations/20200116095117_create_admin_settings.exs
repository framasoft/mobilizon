defmodule Mobilizon.Repo.Migrations.CreateAdminSettings do
  use Ecto.Migration

  def change do
    create table(:admin_settings) do
      add(:group, :string)
      add(:name, :string)
      add(:value, :text)

      timestamps()
    end

    create(unique_index(:admin_settings, [:group, :name]))
  end
end
