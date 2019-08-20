defmodule Mobilizon.Repo.Migrations.AddUrlAndUuidToParticipants do
  use Ecto.Migration

  def up do
    drop(index(:participants, :event_id))
    drop_if_exists(index(:participants, :account_id))
    drop_if_exists(index(:participants, :actor_id))
    drop(constraint(:participants, "participants_event_id_fkey"))

    # This is because even though we renamed the table accounts to actors indexes kept this name
    drop_if_exists(constraint(:participants, "participants_account_id_fkey"))
    drop_if_exists(constraint(:participants, "participants_actor_id_fkey"))
    drop(constraint(:participants, "participants_pkey"))

    alter table(:participants, primary_key: false) do
      modify(:event_id, references(:events, on_delete: :delete_all), primary_key: false)
      modify(:actor_id, references(:actors, on_delete: :delete_all), primary_key: false)
      add(:id, :uuid, primary_key: true)
      add(:url, :string, null: false)
    end

    create(index(:participants, :event_id))
    create(index(:participants, :actor_id))
  end

  def down do
    drop(index(:participants, :event_id))
    drop(index(:participants, :actor_id))
    drop(constraint(:participants, "participants_event_id_fkey"))
    drop(constraint(:participants, "participants_actor_id_fkey"))
    drop(constraint(:participants, "participants_pkey"))

    alter table(:participants, primary_key: false) do
      modify(:event_id, references(:events, on_delete: :nothing), primary_key: true)
      modify(:actor_id, references(:actors, on_delete: :nothing), primary_key: true)
      remove(:id)
      remove(:url)
    end

    create(index(:participants, :event_id))
    create(index(:participants, :actor_id))
  end
end
