defmodule Mobilizon.Repo.Migrations.Prerequites do
  use Ecto.Migration

  def up do
    execute("""
    CREATE TYPE datetimetz AS (
        dt timestamptz,
        tz varchar
    );
    """)

    execute("CREATE EXTENSION IF NOT EXISTS postgis")
  end

  def down do
    execute("DROP TYPE IF EXISTS datetimetz;")
    execute("DROP EXTENSION IF EXISTS postgis")
  end
end
