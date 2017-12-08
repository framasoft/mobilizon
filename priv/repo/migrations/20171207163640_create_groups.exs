defmodule Eventos.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :title, :string
      add :description, :string
      add :suspended, :boolean, default: false, null: false
      add :url, :string
      add :uri, :string

      timestamps()
    end

  end
end
