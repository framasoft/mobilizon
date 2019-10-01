defmodule Mobilizon.Storage.Repo.Migrations.AddLocaleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:locale, :string, default: "en")
    end
  end
end
