defmodule Mobilizon.Storage.Repo.Migrations.AddLastRefreshedAtToActors do
  use Ecto.Migration

  def change do
    alter table(:actors) do
      add(:last_refreshed_at, :utc_datetime, null: true)
    end
  end
end
