defmodule Mobilizon.Storage.Repo.Migrations.FixPictureDeletion do
  use Ecto.Migration

  def up do
    drop_if_exists(constraint(:posts, "posts_picture_id_fkey"))

    alter table(:posts) do
      modify(:picture_id, references(:pictures, on_delete: :nilify_all))
    end

    drop_if_exists(constraint(:events, "events_picture_id_fkey"))

    alter table(:events) do
      modify(:picture_id, references(:pictures, on_delete: :nilify_all))
    end
  end

  def down do
    drop_if_exists(constraint(:posts, "posts_picture_id_fkey"))

    alter table(:posts) do
      modify(:picture_id, references(:pictures, on_delete: :delete_all))
    end

    drop_if_exists(constraint(:events, "events_picture_id_fkey"))

    alter table(:events) do
      modify(:picture_id, references(:pictures, on_delete: :delete_all))
    end
  end
end
