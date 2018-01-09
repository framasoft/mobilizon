defmodule Eventos.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :username, :string, null: false
      add :domain, :string
      add :display_name, :string, null: false
      add :description, :text
      add :private_key, :text
      add :public_key, :text, null: false
      add :suspended, :boolean, default: false, null: false
      add :uri, :string
      add :url, :string

      timestamps()
    end

    create unique_index(:accounts, [:username, :domain])

  end
end
