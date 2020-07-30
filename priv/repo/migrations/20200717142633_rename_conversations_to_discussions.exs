defmodule Mobilizon.Storage.Repo.Migrations.RenameConversationsToDiscussions do
  use Ecto.Migration

  def up do
    rename(table("conversations"), to: table("discussions"))
    rename(table("comments"), :conversation_id, to: :discussion_id)

    alter table(:actors) do
      add(:discussions_url, :string, null: true)
    end
  end

  def down do
    rename(table("discussions"), to: table("conversations"))
    rename(table("comments"), :discussion_id, to: :conversation_id)

    alter table(:actors) do
      remove(:discussions_url)
    end
  end
end
