defmodule Mobilizon.Storage.Repo.Migrations.AddNumberEditsToComment do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add(:edits, :integer, default: 0)
    end
  end
end
