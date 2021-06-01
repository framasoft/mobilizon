defmodule Mobilizon.Storage.Repo.Migrations.AddUserActivitySettings do
  use Ecto.Migration

  def change do
    create table(:user_activity_settings) do
      add(:key, :string, nulla: false)
      add(:method, :string, null: false)
      add(:enabled, :boolean, null: false)

      add(:user_id, references(:users, on_delete: :delete_all), null: false)
    end

    create(unique_index(:user_activity_settings, [:user_id, :key, :method]))
  end
end
