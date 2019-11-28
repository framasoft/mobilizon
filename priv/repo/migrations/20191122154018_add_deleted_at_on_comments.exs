defmodule Mobilizon.Storage.Repo.Migrations.AddDeletedAtOnComments do
  use Ecto.Migration

  def up do
    drop_if_exists(constraint(:comments, "comments_actor_id_fkey"))

    alter table(:comments) do
      add(:deleted_at, :utc_datetime, null: true)
      modify(:actor_id, references(:actors, on_delete: :nilify_all), null: true)
    end
  end

  def down do
    drop_if_exists(constraint(:comments, "comments_actor_id_fkey"))

    alter table(:comments) do
      remove(:deleted_at)
      modify(:actor_id, references(:actors, on_delete: :nilify_all), null: false)
    end
  end
end
