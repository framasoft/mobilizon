defmodule Mobilizon.Repo.Migrations.EventEventTagOnDelete do
  use Ecto.Migration

  def up do
    drop(constraint(:events_tags, "events_tags_event_id_fkey"))
    drop(constraint(:events_tags, "events_tags_tag_id_fkey"))

    alter table(:events_tags) do
      modify(:event_id, references(:events, on_delete: :delete_all))
      modify(:tag_id, references(:tags, on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:events_tags, "events_tags_event_id_fkey"))
    drop(constraint(:events_tags, "events_tags_tag_id_fkey"))

    alter table(:events_tags) do
      modify(:event_id, references(:events))
      modify(:tag_id, references(:tags))
    end
  end
end
