defmodule Mobilizon.Storage.Repo.Migrations.AddMetadataToMedia do
  use Ecto.Migration

  def change do
    alter table(:medias) do
      add(:metadata, :map)
    end
  end
end
