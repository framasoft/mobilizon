defmodule Mobilizon.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add(:username, :string, null: false)
      add(:domain, :string, null: true)
      add(:display_name, :string, null: true)
      add(:description, :text, null: true)
      add(:private_key, :text, null: true)
      add(:public_key, :text, null: false)
      add(:suspended, :boolean, default: false, null: false)
      add(:uri, :string, null: false)
      add(:url, :string, null: false)

      timestamps()
    end

    create(unique_index(:accounts, [:username, :domain]))
  end
end
