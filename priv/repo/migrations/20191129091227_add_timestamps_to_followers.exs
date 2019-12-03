defmodule Mobilizon.Storage.Repo.Migrations.AddTimestampsToFollowers do
  use Ecto.Migration

  def change do
    alter table(:followers) do
      timestamps()
    end
  end
end
