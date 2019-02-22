defmodule Mobilizon.Repo.Migrations.CreateSearchIndexes do
  use Ecto.Migration

  def change do
    IO.puts("\n
    #########################################################
    # If the CREATE EXTENSION or DROP EXTENSION calls fail, #
    # please manually execute them with an authorized       #
    # PostgreSQL user with SUPER USER role.                 #
    #########################################################
    \n
    ")

    try do
      execute("CREATE EXTENSION IF NOT EXISTS pg_trgm", "DROP EXTENSION IF EXISTS pg_trgm")
      execute("CREATE EXTENSION IF NOT EXISTS unaccent", "DROP EXTENSION IF EXISTS unaccent")

      execute(
        "CREATE OR REPLACE FUNCTION public.f_unaccent(text)
  RETURNS text AS
$func$
SELECT public.unaccent('public.unaccent', $1)
$func$  LANGUAGE sql IMMUTABLE;",
        "DROP FUNCTION IF EXISTS public.f_unaccent"
      )

      execute(
        "CREATE INDEX \"event_title_trigram\" ON \"events\" USING GIN (f_unaccent(title) gin_trgm_ops)",
        "DROP INDEX IF EXISTS event_title_trigram"
      )

      execute(
        "CREATE INDEX \"actor_preferred_username_trigram\" ON \"actors\"
    USING GIN (f_unaccent(preferred_username) gin_trgm_ops)",
        "DROP INDEX IF EXISTS actor_preferred_username_trigram"
      )

      execute(
        "CREATE INDEX \"actor_name_trigram\" ON \"actors\"
    USING GIN (f_unaccent(name) gin_trgm_ops)",
        "DROP INDEX IF EXISTS actor_name_trigram"
      )
    rescue
      e in Postgrex.Error ->
        IO.puts(e.message)
    end
  end
end
