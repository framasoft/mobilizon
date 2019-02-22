defmodule Mobilizon.Repo.Migrations.RevertAlterEventTimestampsToDateTimeWithTimeZone do
  use Ecto.Migration

  def up do
    alter table(:events) do
      modify(:inserted_at, :timestamptz)
      modify(:updated_at, :timestamptz)
    end
  end

  def down do
    alter table(:events) do
      modify(:inserted_at, :utc_datetime)
      modify(:updated_at, :utc_datetime)
    end
  end
end
