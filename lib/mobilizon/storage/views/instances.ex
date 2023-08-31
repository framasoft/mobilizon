defmodule Mobilizon.Storage.Views.Instances do
  @moduledoc """
  SQL code for PostgreSQL instances materialized view
  """

  def create_materialized_view do
    """
    CREATE MATERIALIZED VIEW instances AS
    SELECT
      a.domain,
      COUNT(DISTINCT(p.id)) AS person_count,
      COUNT(DISTINCT(g.id)) AS group_count,
      COUNT(DISTINCT(e.id)) AS event_count,
      COUNT(f1.id) AS followers_count,
      COUNT(f2.id) AS followings_count,
      COUNT(r.id) AS reports_count,
      SUM(COALESCE((m.file->>'size')::int, 0)) AS media_size
    FROM actors a
    LEFT JOIN actors p ON a.id = p.id AND p.type = 'Person'
    LEFT JOIN actors g ON a.id = g.id AND g.type = 'Group'
    LEFT JOIN events e ON a.id = e.organizer_actor_id
    LEFT JOIN followers f1 ON a.id = f1.actor_id
    LEFT JOIN followers f2 ON a.id = f2.target_actor_id
    LEFT JOIN reports r ON r.reported_id = a.id
    LEFT JOIN medias m ON m.actor_id = a.id
    WHERE a.domain IS NOT NULL
    GROUP BY a.domain;
    """
  end

  def refresh_instances do
    """
    CREATE OR REPLACE FUNCTION refresh_instances()
    RETURNS trigger AS $$
    BEGIN
      REFRESH MATERIALIZED VIEW instances;
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    """
  end

  def drop_trigger do
    """
    DROP TRIGGER IF EXISTS refresh_instances_trigger ON actors;
    """
  end

  def create_trigger do
    """
    CREATE TRIGGER refresh_instances_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON actors
    FOR EACH STATEMENT
    EXECUTE PROCEDURE refresh_instances();
    """
  end

  def drop_refresh_instances do
    """
    DROP FUNCTION IF EXISTS refresh_instances() CASCADE;
    """
  end

  def drop_view do
    """
    DROP MATERIALIZED VIEW IF EXISTS instances;
    """
  end
end
