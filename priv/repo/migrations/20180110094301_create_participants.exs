defmodule Mobilizon.Repo.Migrations.CreateParticipants do
  use Ecto.Migration

  def change do
    create table(:participants, primary_key: false) do
      add(:role, :integer)
      add(:event_id, references(:events, on_delete: :nothing), primary_key: true)
      add(:account_id, references(:accounts, on_delete: :nothing), primary_key: true)

      timestamps()
    end

    create(index(:participants, [:event_id]))
    create(index(:participants, [:account_id]))
  end
end
