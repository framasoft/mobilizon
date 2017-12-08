defmodule Eventos.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :title, :string, null: false
      add :description, :text
      add :begin_on, :utc_datetime
      add :ends_on, :utc_datetime
      add :organizer_id, references(:accounts, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:events, [:organizer_id])
  end
end
