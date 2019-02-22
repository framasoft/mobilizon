defmodule Mobilizon.Repo.Migrations.AddBotsTable do
  use Ecto.Migration

  def up do
    create table(:bots) do
      add(:source, :string, null: false)
      add(:type, :string, default: "ics")
      add(:actor_id, references(:actors, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end
  end

  def down do
    drop(table(:bots))
  end
end
