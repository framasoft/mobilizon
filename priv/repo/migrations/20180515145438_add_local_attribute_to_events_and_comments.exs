defmodule Mobilizon.Repo.Migrations.AddLocalAttributeToEventsAndComments do
  use Ecto.Migration

  def up do
    alter table("events") do
      add(:local, :boolean, null: false, default: true)
    end

    alter table("comments") do
      add(:local, :boolean, null: false, default: true)
    end
  end

  def down do
    alter table("events") do
      remove(:local)
    end

    alter table("comments") do
      remove(:local)
    end
  end
end
