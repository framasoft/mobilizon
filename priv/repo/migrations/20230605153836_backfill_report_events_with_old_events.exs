defmodule Mobilizon.Storage.Repo.Migrations.BackfillReportEventsWithOldEvents do
  use Ecto.Migration

  def up do
    process_reports_with_events()
  end

  def down do
    IO.puts("Doing nothing, migration can't be reverted")
  end

  defp process_reports_with_events do
    %Postgrex.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(
        Mobilizon.Storage.Repo,
        "SELECT id, event_id FROM reports WHERE event_id IS NOT NULL"
      )

    Enum.map(rows, &migrate_event_row/1)
  end

  defp migrate_event_row([report_id, event_id]) when not is_nil(event_id) do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "INSERT INTO reports_events VALUES ($1, $2)",
      [report_id, event_id]
    )
  end

  defp migrate_event_row(_), do: :ok
end
