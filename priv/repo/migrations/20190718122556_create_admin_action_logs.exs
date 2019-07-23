defmodule Mobilizon.Repo.Migrations.CreateAdminActionLogs do
  use Ecto.Migration

  def change do
    create table(:admin_action_logs) do
      add(:action, :string, null: false)
      add(:target_type, :string, null: false)
      add(:target_id, :int, null: false)
      add(:changes, :map)
      add(:actor_id, references(:actors, on_delete: :nilify_all), null: false)

      timestamps()
    end
  end
end
