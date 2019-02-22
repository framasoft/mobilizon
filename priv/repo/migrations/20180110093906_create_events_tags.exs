defmodule Mobilizon.Repo.Migrations.CreateEventsTags do
  use Ecto.Migration

  def change do
    create table(:events_tags, primary_key: false) do
      add(:event_id, references(:events))
      add(:tag_id, references(:tags))
    end
  end
end
