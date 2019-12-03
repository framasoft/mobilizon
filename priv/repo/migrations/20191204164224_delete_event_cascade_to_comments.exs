defmodule Mobilizon.Storage.Repo.Migrations.DeleteEventCascadeToComments do
  use Ecto.Migration

  def up do
    drop_if_exists(constraint(:comments, "comments_event_id_fkey"))

    alter table(:comments) do
      modify(:event_id, references(:events, on_delete: :delete_all))
    end
  end

  def down do
    drop_if_exists(constraint(:comments, "comments_event_id_fkey"))

    alter table(:comments) do
      modify(:event_id, references(:events, on_delete: :nothing))
    end
  end
end
