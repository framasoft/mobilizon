defmodule Mobilizon.Storage.Repo.Migrations.AddMetadataToParticipant do
  use Ecto.Migration

  def up do
    drop_if_exists(unique_index(:participants, [:event_id, :actor_id]))

    alter table(:participants) do
      add(:metadata, :map)
    end

    flush()

    execute(
      "CREATE UNIQUE INDEX participants_metadata_confirmation_token_index ON participants((metadata->>'confirmation_token'))"
    )
  end

  def down do
    create_if_not_exists(unique_index(:participants, [:event_id, :actor_id]))

    execute("DROP INDEX IF EXISTS participants_metadata_confirmation_token_index")

    alter table(:participants) do
      remove(:metadata, :map)
    end
  end
end
