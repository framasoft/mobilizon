defmodule Mobilizon.Storage.Repo.Migrations.FixObanMigrationsForOlderPostgreSQLVersions do
  use Ecto.Migration

  @disable_ddl_transaction true
  def up do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "ALTER TYPE oban_job_state ADD VALUE IF NOT EXISTS 'cancelled'"
    )
  end

  def down do
    IO.puts("This migration doesn't handle being reverted.")
  end
end
