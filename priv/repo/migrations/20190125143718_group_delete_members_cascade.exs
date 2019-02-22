defmodule Mobilizon.Repo.Migrations.GroupDeleteMembersCascade do
  use Ecto.Migration

  def change do
    drop(constraint(:members, "members_account_id_fkey"))
    drop(constraint(:members, "members_parent_id_fkey"))

    alter table(:members) do
      modify(:actor_id, references(:actors, on_delete: :delete_all))
      modify(:parent_id, references(:actors, on_delete: :delete_all))
    end
  end
end
