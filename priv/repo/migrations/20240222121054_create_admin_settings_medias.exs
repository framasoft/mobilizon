defmodule Mobilizon.Storage.Repo.Migrations.CreateAdminSettingsMedias do
  use Ecto.Migration

  def change do
    create table(:admin_settings_medias) do
      add(:group, :string)
      add(:name, :string)
      add(:media_id, references(:medias, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:admin_settings_medias, [:group, :name]))
  end
end
