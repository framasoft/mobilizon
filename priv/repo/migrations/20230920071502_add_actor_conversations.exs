defmodule Mobilizon.Storage.Repo.Migrations.AddActorConversations do
  use Ecto.Migration

  def up do
    create table(:conversations) do
      add(:event_id, references(:events, on_delete: :delete_all), null: true)
      add(:origin_comment_id, references(:comments, on_delete: :delete_all), null: false)
      add(:last_comment_id, references(:comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create table(:conversation_participants) do
      add(:conversation_id, references(:conversations, on_delete: :delete_all), null: false)

      add(:actor_id, references(:actors, on_delete: :delete_all), null: false)

      add(:unread, :boolean, default_value: true)

      timestamps()
    end

    alter table(:comments) do
      add(:conversation_id, references(:conversations, on_delete: :delete_all), null: true)
    end
  end

  def down do
    drop table(:conversation_participants)

    alter table(:comments) do
      remove(:conversation_id)
    end

    drop table(:conversations)
  end
end
