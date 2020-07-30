defmodule Mobilizon.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  alias Mobilizon.Posts.PostVisibility

  def up do
    PostVisibility.create_type()

    create table(:posts, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:title, :string)
      add(:slug, :string)
      add(:url, :string)
      add(:body, :text)
      add(:draft, :boolean, default: false, null: false)
      add(:local, :boolean, default: true, null: false)
      add(:visibility, PostVisibility.type(), default: "public")
      add(:publish_at, :utc_datetime)
      add(:author_id, references(:actors, on_delete: :delete_all))
      add(:attributed_to_id, references(:actors, on_delete: :delete_all))
      add(:picture_id, references(:pictures, on_delete: :delete_all))

      timestamps()
    end

    create table(:posts_tags, primary_key: false) do
      add(:post_id, references(:posts, on_delete: :delete_all, type: :uuid), primary_key: true)
      add(:tag_id, references(:tags, on_delete: :delete_all), primary_key: true)
    end

    alter table(:actors) do
      add(:posts_url, :string, null: true)
      add(:events_url, :string, null: true)
    end
  end

  def down do
    drop(table(:posts_tags))
    drop(table(:posts))
    PostVisibility.drop_type()

    alter table(:actors) do
      remove(:posts_url, :string, null: true)
      remove(:events_url, :string, null: true)
    end
  end
end
