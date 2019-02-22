defmodule Mobilizon.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string, null: false)
      add(:role, :integer, default: 0, null: false)
      add(:password_hash, :string, null: false)
      add(:account_id, references(:accounts, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:users, [:email]))
  end
end
