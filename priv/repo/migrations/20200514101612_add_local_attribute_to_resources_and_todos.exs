defmodule Mobilizon.Storage.Repo.Migrations.AddLocalAttributeToResourcesAndTodos do
  use Ecto.Migration

  def change do
    alter table(:resource) do
      add(:local, :boolean, default: true)
    end

    alter table(:todo_lists) do
      add(:local, :boolean, default: true)
    end

    alter table(:todos) do
      add(:local, :boolean, default: true)
    end
  end
end
