defmodule Eventos.Repo.Migrations.AlterEventTimestampsToDateTimeWithTimeZone do
  use Ecto.Migration

  def up do
    alter table("events") do
      modify :inserted_at, :utc_datetime
      modify :updated_at, :utc_datetime
    end
  end

  def down do
    alter table("events") do
      modify :inserted_at, :naive_datetime
      modify :updated_at, :naive_datetime
    end
  end
end
