defmodule Mobilizon.Storage.Repo.Migrations.AddMentionTables do
  use Ecto.Migration

  def change do
    create table(:mentions) do
      add(:silent, :boolean, default: false, null: false)
      add(:actor_id, references(:actors, on_delete: :delete_all), null: false)
      add(:event_id, references(:events, on_delete: :delete_all), null: true)
      add(:comment_id, references(:comments, on_delete: :delete_all), null: true)

      timestamps()
    end

    create(index(:mentions, [:actor_id]))
  end
end
