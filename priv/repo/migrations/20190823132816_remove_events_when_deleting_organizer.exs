defmodule Mobilizon.Repo.Migrations.RemoveEventsWhenDeletingOrganizer do
  use Ecto.Migration

  def up do
    drop(constraint(:events, "events_organizer_account_id_fkey"))

    alter table(:events) do
      modify(:organizer_actor_id, references(:actors, on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:events, "events_organizer_actor_id_fkey"))

    alter table(:events) do
      modify(:organizer_actor_id, references(:actors, on_delete: :nothing))
    end
  end
end
