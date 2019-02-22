defmodule Mobilizon.Repo.Migrations.DropDatetimetz do
  use Ecto.Migration

  def up do
    alter table(:events) do
      remove(:begins_on)
      remove(:ends_on)
      remove(:publish_at)
      add(:begins_on, :utc_datetime)
      add(:ends_on, :utc_datetime)
      add(:publish_at, :utc_datetime)
    end

    alter table(:sessions) do
      remove(:begins_on)
      remove(:ends_on)
      add(:begins_on, :utc_datetime)
      add(:ends_on, :utc_datetime)
    end

    execute("DROP TYPE datetimetz")
  end

  def down do
    execute("""
    CREATE TYPE datetimetz AS (
        dt timestamptz,
        tz varchar
    );
    """)

    alter table(:events) do
      remove(:begins_on)
      remove(:ends_on)
      remove(:publish_at)
      add(:begins_on, :datetimetz)
      add(:ends_on, :datetimetz)
      add(:publish_at, :datetimetz)
    end

    alter table(:sessions) do
      remove(:begins_on)
      remove(:ends_on)
      add(:begins_on, :datetimetz)
      add(:ends_on, :datetimetz)
    end
  end
end
