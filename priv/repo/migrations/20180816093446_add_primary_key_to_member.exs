defmodule Mobilizon.Repo.Migrations.AddPrimaryKeyToMember do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE members DROP CONSTRAINT IF EXISTS members_pkey")
    drop_if_exists(index(:members, ["members_account_id_index"]))

    create(
      unique_index(:members, [:actor_id, :parent_id], name: :members_actor_parent_unique_index)
    )

    alter table(:members) do
      add(:id, :serial, primary_key: true)
    end
  end

  def down do
    drop(index(:members, [:actor_id, :parent_id], name: :members_actor_parent_unique_index))

    alter table(:members) do
      remove(:id)
    end
  end
end
