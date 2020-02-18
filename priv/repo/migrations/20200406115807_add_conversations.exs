defmodule Mobilizon.Storage.Repo.Migrations.AddConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add(:title, :string)
      add(:slug, :string)
      add(:actor_id, references(:actors, on_delete: :delete_all), null: false)
      add(:creator_id, references(:actors, on_delete: :nilify_all))
      add(:last_comment_id, references(:comments, on_delete: :delete_all))
      timestamps()
    end

    alter table(:comments) do
      add(:conversation_id, references(:conversations, on_delete: :delete_all))
    end
  end
end
