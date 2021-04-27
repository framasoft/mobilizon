defmodule Mobilizon.Storage.Repo.Migrations.RepairUsersDefaultActors do
  use Ecto.Migration

  def up do
    rows = fetch_bad_rows()
    Enum.each(rows, &process_row/1)
  end

  def down do
    # Nothing to do
  end

  defp fetch_bad_rows() do
    %Postgrex.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(
        Mobilizon.Storage.Repo,
        "SELECT u.id FROM users u JOIN actors a ON u.default_actor_id = a.id WHERE a.user_id IS NULL"
      )

    rows
  end

  defp process_row([user_id]) do
    user_id
    |> find_first_actor_id()
    |> repair_user_default_actor(user_id)
  end

  defp find_first_actor_id(user_id) do
    %Postgrex.Result{rows: [[id]]} =
      Ecto.Adapters.SQL.query!(
        Mobilizon.Storage.Repo,
        "SELECT id FROM actors WHERE user_id = $1 AND type = 'Person' AND NOT suspended ORDER BY id LIMIT 1",
        [user_id]
      )

    id
  end

  defp repair_user_default_actor(actor_id, user_id) do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "UPDATE users SET default_actor_id = $1 WHERE id = $2",
      [actor_id, user_id]
    )
  end
end
