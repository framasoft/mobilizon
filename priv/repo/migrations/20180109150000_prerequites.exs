defmodule Eventos.Repo.Migrations.Prerequites do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE datetimetz AS (
        dt timestamptz,
        tz varchar
    );
    """
  end

  def down do
    execute "DROP TYPE IF EXISTS datetimetz;"
  end
end
