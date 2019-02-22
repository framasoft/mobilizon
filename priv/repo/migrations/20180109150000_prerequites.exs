defmodule Mobilizon.Repo.Migrations.Prerequites do
  use Ecto.Migration

  def up do
    IO.puts("\n
    #########################################################
    # If the CREATE EXTENSION or DROP EXTENSION calls fail, #
    # please manually execute them with an authorized       #
    # PostgreSQL user with SUPER USER role.                 #
    #########################################################
    \n
    ")

    execute("""
    CREATE TYPE datetimetz AS (
        dt timestamptz,
        tz varchar
    );
    """)

    execute("CREATE EXTENSION IF NOT EXISTS postgis")
    execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    execute("CREATE EXTENSION IF NOT EXISTS unaccent")
  end

  def down do
    IO.puts("\n
    #########################################################
    # If the CREATE EXTENSION or DROP EXTENSION calls fail, #
    # please manually execute them with an authorized       #
    # PostgreSQL user with SUPER USER role.                 #
    #########################################################
    \n
    ")

    execute("DROP TYPE IF EXISTS datetimetz;")
    execute("DROP EXTENSION IF EXISTS postgis")
    execute("DROP EXTENSION IF EXISTS pg_trgm")
    execute("DROP EXTENSION IF EXISTS unaccent")
  end
end
