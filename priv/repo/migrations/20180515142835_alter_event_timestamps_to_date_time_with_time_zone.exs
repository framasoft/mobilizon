defmodule Mobilizon.Repo.Migrations.AlterEventTimestampsToDateTimeWithTimeZone do
  use Ecto.Migration

  def up do
    alter table("events") do
      modify(:inserted_at, :utc_datetime)
      modify(:updated_at, :utc_datetime)
    end
  end

  def down do
    alter table("events") do
      modify(:inserted_at, :timestamptz)
      modify(:updated_at, :timestamptz)
    end
  end
end
