defmodule Mobilizon.Storage.Repo.Migrations.AddLanguageToEntities do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:language, :string, default: "und")
    end

    alter table(:comments) do
      add(:language, :string, default: "und")
    end

    alter table(:posts) do
      add(:language, :string, default: "und")
    end
  end
end
