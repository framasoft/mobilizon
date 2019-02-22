defmodule Mobilizon.Repo.Migrations.RemoveUri do
  use Ecto.Migration

  def up do
    alter table("accounts") do
      remove(:uri)
    end

    alter table("groups") do
      remove(:uri)
    end
  end

  def down do
    alter table("accounts") do
      add(:uri, :string, null: false, default: "https://")
    end

    alter table("groups") do
      add(:uri, :string, null: false, default: "https://")
    end
  end
end
