defmodule Mobilizon.Storage.Repo.Migrations.AddMetadataForEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:metadata, :map)
    end
  end
end
