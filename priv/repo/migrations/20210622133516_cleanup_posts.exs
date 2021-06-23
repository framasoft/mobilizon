defmodule Mobilizon.Storage.Repo.Migrations.CleanupPosts do
  use Ecto.Migration

  def up do
    # Make sure we don't have any duplicate posts
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
          ROW_NUMBER() OVER(PARTITION BY url ORDER BY inserted_at asc) AS Row
          FROM posts
        ) dups
        WHERE dups.Row > 1;"
      )

    rows
  end

  defp process_row([id, url, _row]) do
    first_id = find_first_post_id(url)

    if id != first_id do
      repair_post_medias(id, first_id)
      repair_post_tags(id, first_id)
      delete_row(id)
    end
  end

  defp find_first_post_id(url) do
    %Postgrex.Result{rows: [[id]]} =
      Ecto.Adapters.SQL.query!(
        Mobilizon.Storage.Repo,
        "SELECT id FROM posts WHERE url = $1 order by inserted_at asc limit 1",
        [url]
      )

    id
  end

  defp repair_post_medias(id, first_id) do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "UPDATE posts_medias SET post_id = $1 WHERE post_id = $2",
      [first_id, id]
    )
  end

  defp repair_post_tags(id, first_id) do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "UPDATE posts_tags SET post_id = $1 WHERE post_id = $2",
      [first_id, id]
    )
  end

  defp delete_row(id) do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "DELETE FROM posts WHERE id = $1",
      [id]
    )
  end
end
