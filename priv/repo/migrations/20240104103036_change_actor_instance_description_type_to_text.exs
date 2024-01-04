defmodule Mobilizon.Storage.Repo.Migrations.ChangeActorInstanceDescriptionTypeToText do
  use Ecto.Migration

  def up do
    alter table(:instance_actors) do
      modify(:instance_description, :text)
    end
  end

  def down do
    alter table(:instance_actors) do
      modify(:instance_description, :string)
    end
  end
end
