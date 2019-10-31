defmodule Mobilizon.Storage.Repo.Migrations.AddTagsToComments do
  use Ecto.Migration

  def up do
    create table(:comments_tags, primary_key: false) do
      add(:comment_id, references(:comments, on_delete: :delete_all), primary_key: true)
      add(:tag_id, references(:tags, on_delete: :nilify_all), primary_key: true)
    end
  end

  def down do
    drop(table(:comments_tags))
  end
end
