defmodule Mobilizon.Repo.Migrations.CreateTombstones do
  use Ecto.Migration

  def change do
    create table(:tombstones) do
      add(:uri, :string)
      add(:actor_id, references(:actors, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:tombstones, [:uri]))
  end
end
