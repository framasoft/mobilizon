defmodule Mobilizon.Storage.Repo.Migrations.AddResourcesAndTodosEndpointsToActor do
  use Ecto.Migration

  def change do
    alter table(:actors) do
      add(:resources_url, :string, null: true)
      add(:todos_url, :string, null: true)
    end
  end
end
