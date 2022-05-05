defmodule Mobilizon.Storage.Repo.Migrations.ChangeRefreshInstanceTriggerToOnlyExecuteOnRelays do
  use Ecto.Migration

  def up do
    execute("""
    DROP TRIGGER IF EXISTS refresh_instances_trigger ON actors;
    """)

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

  def down do
    execute("""
    DROP TRIGGER IF EXISTS refresh_instances_trigger_new ON actors;
    """)

    execute("""
    DROP TRIGGER IF EXISTS refresh_instances_trigger_old ON actors;
    """)

    execute("""
    CREATE TRIGGER refresh_instances_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON actors
    FOR EACH STATEMENT
    EXECUTE PROCEDURE refresh_instances();
    """)
  end
end
