defmodule Mobilizon.Storage.Repo.Migrations.AddMediaTables do
  use Ecto.Migration

  def change do
    rename(table(:pictures), to: table(:medias))

    create table(:events_medias, primary_key: false) do
      add(:event_id, references(:events, on_delete: :delete_all), primary_key: true)
      add(:media_id, references(:medias, on_delete: :delete_all), primary_key: true)
    end

    create table(:posts_medias, primary_key: false) do
      add(:post_id, references(:posts, on_delete: :delete_all, type: :uuid), primary_key: true)
      add(:media_id, references(:medias, on_delete: :delete_all), primary_key: true)
    end

    create table(:comments_medias, primary_key: false) do
      add(:comment_id, references(:comments, on_delete: :delete_all), primary_key: true)
      add(:media_id, references(:medias, on_delete: :delete_all), primary_key: true)
    end
  end
end
