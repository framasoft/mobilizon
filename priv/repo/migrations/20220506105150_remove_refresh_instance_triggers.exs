defmodule Mobilizon.Storage.Repo.Migrations.RemoveRefreshInstanceTriggers do
  use Ecto.Migration

  def up do
    execute("""
    DROP TRIGGER IF EXISTS refresh_instances_trigger_new ON actors;
    """)

    execute("""
    DROP TRIGGER IF EXISTS refresh_instances_trigger_old ON actors;
    """)
  end

  def down do
    execute("""
    CREATE TRIGGER refresh_instances_trigger_new
    AFTER INSERT OR UPDATE
    ON actors
    FOR EACH ROW
    WHEN (NEW.preferred_username = 'relay')
    EXECUTE PROCEDURE refresh_instances();
    """)

    execute("""
    CREATE TRIGGER refresh_instances_trigger_old
    AFTER DELETE
    ON actors
    FOR EACH ROW
    WHEN (OLD.preferred_username = 'relay')
    EXECUTE PROCEDURE refresh_instances();
    """)
  end
end
