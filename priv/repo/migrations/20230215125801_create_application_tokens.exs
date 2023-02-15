defmodule Mobilizon.Repo.Migrations.CreateApplicationTokens do
  use Ecto.Migration

  def change do
    create table(:application_tokens) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:application_id, references(:applications, on_delete: :delete_all), null: false)
      add(:authorization_code, :string, null: true)
      timestamps()
    end

    create(unique_index(:application_tokens, [:user_id, :application_id]))
  end
end
