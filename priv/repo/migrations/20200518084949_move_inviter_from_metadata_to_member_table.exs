defmodule Mobilizon.Storage.Repo.Migrations.MoveInviterFromMetadataToMemberTable do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add(:invited_by_id, references(:actors, on_delete: :nilify_all))
    end
  end
end
