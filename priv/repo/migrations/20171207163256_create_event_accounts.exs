defmodule Eventos.Repo.Migrations.CreateEventAccounts do
  use Ecto.Migration

  def change do
    create table(:event_accounts, primary_key: false) do
      add :roles, :integer
      add :event_id, references(:events, on_delete: :nothing)
      add :account_id, references(:accounts, on_delete: :nothing)

      timestamps()
    end

    create index(:event_accounts, [:event_id])
    create index(:event_accounts, [:account_id])
  end
end
