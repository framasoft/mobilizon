defmodule Mobilizon.Repo.Migrations.CreateEventRequests do
  use Ecto.Migration

  def change do
    create table(:event_requests) do
      add(:state, :integer)
      add(:event_id, references(:events, on_delete: :nothing))
      add(:account_id, references(:accounts, on_delete: :nothing))

      timestamps()
    end

    create(index(:event_requests, [:event_id]))
    create(index(:event_requests, [:account_id]))
  end
end
