defmodule Mobilizon.Storage.Repo.Migrations.AddUrlToConversation do
  use Ecto.Migration

  def up do
    # Just in case old name is used
    drop_if_exists(constraint(:comments, :comments_conversation_id_fkey))
    drop_if_exists(constraint(:comments, :comments_discussion_id_fkey))

    alter table(:discussions, primary_key: false) do
      remove(:id)
      add(:id, :uuid, primary_key: true)
      add(:url, :string, null: false)
    end

    alter table(:comments) do
      remove(:discussion_id)
      add(:discussion_id, references(:discussions, type: :uuid), null: true)
    end
  end

  def down do
    drop_if_exists(constraint(:comments, :comments_conversation_id_fkey))
    drop_if_exists(constraint(:comments, :comments_discussion_id_fkey))

    alter table(:discussions, primary_key: true) do
      remove(:id)
      add(:id, :serial, primary_key: true)
      remove(:url)
    end

    alter table(:comments) do
      remove(:discussion_id)
      add(:discussion_id, references(:discussions, type: :serial), null: true)
    end
  end
end
