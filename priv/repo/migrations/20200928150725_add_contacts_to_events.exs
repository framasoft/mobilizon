defmodule Mobilizon.Storage.Repo.Migrations.AddContactsToEvents do
  use Ecto.Migration

  def change do
    create table(:event_contacts, primary_key: false) do
      add(:event_id, references(:events, on_delete: :delete_all), primary_key: true)
      add(:actor_id, references(:actors, on_delete: :delete_all), primary_key: true)
    end
  end
end
