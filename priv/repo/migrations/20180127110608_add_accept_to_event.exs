defmodule Eventos.Repo.Migrations.AddAcceptToEvent do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :accept, :integer, default: 0, null: false
    end
  end
end
