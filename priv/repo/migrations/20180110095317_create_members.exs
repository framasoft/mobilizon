defmodule Mobilizon.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members, primary_key: false) do
      add(:role, :integer)
      add(:group_id, references(:groups, on_delete: :nothing))
      add(:account_id, references(:accounts, on_delete: :nothing))

      timestamps()
    end

    create(index(:members, [:group_id]))
    create(index(:members, [:account_id]))
  end
end
