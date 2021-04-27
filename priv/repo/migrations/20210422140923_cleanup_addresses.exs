defmodule Mobilizon.Storage.Repo.Migrations.CleanupAddresses do
  use Ecto.Migration

  def up do
    # Make sure we don't have any duplicate addresses
    rows = fetch_bad_rows()
    Enum.each(rows, &process_row/1)
  end

  def down do
    # No way down
  end

  defp fetch_bad_rows() do
    %Postgrex.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(
        Mobilizon.Storage.Repo,
        "SELECT * FROM (
          SELECT id, url,
          ROW_NUMBER() OVER(PARTITION BY url ORDER BY id asc) AS Row
          FROM addresses
        ) dups
        WHERE dups.Row > 1;"
      )

    rows
  end

  defp process_row([id, url, _row]) do
    first_id = find_first_address_id(url)

    if id != first_id do
      repair_events(id, first_id)
      repair_actors(id, first_id)
      delete_row(id)
    end
  end

  defp find_first_address_id(url) do
    %Postgrex.Result{rows: [[id]]} =
      Ecto.Adapters.SQL.query!(
        Mobilizon.Storage.Repo,
        "SELECT id FROM addresses WHERE url = $1 order by id asc limit 1",
        [url]
      )

    id
  end

  defp repair_events(id, first_id) do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "UPDATE events SET physical_address_id = $1 WHERE physical_address_id = $2",
      [first_id, id]
    )
  end

  defp repair_actors(id, first_id) do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "UPDATE actors SET physical_address_id = $1 WHERE physical_address_id = $2",
      [first_id, id]
    )
  end

  defp delete_row(id) do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "DELETE FROM addresses WHERE id = $1",
      [id]
    )
  end
end
