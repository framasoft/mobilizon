defmodule Mobilizon.Storage.Repo.Migrations.AddDraftFlagToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:draft, :boolean, default: false)
    end
  end
end
