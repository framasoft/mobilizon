defmodule Mobilizon.Storage.Repo.Migrations.AddUniqueURLContraintToSomeTables do
  use Ecto.Migration

  def change do
    create(unique_index(:members, [:url]))
    create(unique_index(:resource, [:url]))
    create(unique_index(:todo_lists, [:url]))
    create(unique_index(:todos, [:url]))
  end
end
