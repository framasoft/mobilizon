defmodule Mobilizon.Repo.Migrations.AddUrlFieldToEvents do
  use Ecto.Migration

  def up do
    alter table("events") do
      add(:url, :string, null: false, default: "https://")
    end
  end

  def down do
    alter table("events") do
      remove(:url)
    end
  end
end
