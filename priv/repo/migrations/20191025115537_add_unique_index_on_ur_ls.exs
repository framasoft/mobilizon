defmodule Mobilizon.Storage.Repo.Migrations.AddUniqueIndexOnURLs do
  use Ecto.Migration

  def change do
    create(unique_index(:events, [:url]))
    create(unique_index(:comments, [:url]))
  end
end
