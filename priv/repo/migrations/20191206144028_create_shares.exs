defmodule Mobilizon.Repo.Migrations.CreateShares do
  use Ecto.Migration

  def up do
    create table(:shares) do
      add(:uri, :string, null: false)
      add(:actor_id, references(:actors, on_delete: :delete_all), null: false)
      add(:owner_actor_id, references(:actors, on_delete: :delete_all), null: false)

      timestamps()
    end

    create_if_not_exists(
      index(:shares, [:uri, :actor_id], unique: true, name: :shares_uri_actor_id_index)
    )
  end

  def down do
    drop_if_exists(index(:shares, [:uri, :actor_id]))

    drop_if_exists(table(:shares))
  end
end
