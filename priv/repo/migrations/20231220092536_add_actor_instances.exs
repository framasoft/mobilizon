defmodule Mobilizon.Storage.Repo.Migrations.AddActorInstances do
  use Ecto.Migration

  def change do
    create table(:instance_actors) do
      add(:domain, :string)
      add(:instance_name, :string)
      add(:instance_description, :string)
      add(:software, :string)
      add(:software_version, :string)
      add(:actor_id, references(:actors, on_delete: :delete_all))
      timestamps()
    end

    create(unique_index(:instance_actors, [:domain]))
  end
end
