defmodule Mobilizon.Repo.Migrations.AddDefaultActorUserField do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add(:default_actor_id, :integer)
    end
  end

  def down do
    alter table(:users) do
      remove(:default_actor_id)
    end
  end
end
