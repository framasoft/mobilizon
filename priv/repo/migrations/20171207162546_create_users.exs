defmodule Eventos.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :email, :string
      add :role, :integer, default: 0
      add :account_id, references(:accounts, on_delete: :delete_all, null: false)

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end
