defmodule Eventos.Repo.Migrations.CreateGroupAccounts do
  use Ecto.Migration

  def change do
    create table(:group_accounts, primary_key: false) do
      add :role, :integer
      add :group_id, references(:groups, on_delete: :nothing)
      add :account_id, references(:accounts, on_delete: :nothing)

      timestamps()
    end

    create index(:group_accounts, [:group_id])
    create index(:group_accounts, [:account_id])
  end
end
