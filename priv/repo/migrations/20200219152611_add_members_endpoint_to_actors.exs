defmodule Mobilizon.Storage.Repo.Migrations.AddMembersEndpointToActors do
  use Ecto.Migration

  def up do
    alter table(:actors) do
      add(:members_url, :string, null: true)
    end
  end

  def down do
    alter table(:actors) do
      remove(:members_url)
    end
  end
end
