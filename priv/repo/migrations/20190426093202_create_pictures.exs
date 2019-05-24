defmodule Mobilizon.Repo.Migrations.CreatePictures do
  use Ecto.Migration

  def up do
    create table(:pictures) do
      add(:file, :map)

      timestamps()
    end

    alter table(:actors) do
      remove(:avatar_url)
      remove(:banner_url)
      add(:avatar, :map)
      add(:banner, :map)
    end

    alter table(:events) do
      remove(:thumbnail)
      remove(:large_image)
      add(:picture_id, references(:pictures, on_delete: :delete_all))
    end
  end

  def down do
    alter table(:actors) do
      add(:avatar_url, :string)
      add(:banner_url, :string)
      remove(:avatar)
      remove(:banner)
    end

    alter table(:events) do
      add(:large_image, :string)
      add(:thumbnail, :string)
      remove(:picture_id)
    end

    drop(table(:pictures))
  end
end
