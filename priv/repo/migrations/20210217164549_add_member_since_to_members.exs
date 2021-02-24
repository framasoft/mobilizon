defmodule Mobilizon.Storage.Repo.Migrations.AddMemberSinceToMembers do
  use Ecto.Migration

  def up do
    alter table(:members) do
      add(:member_since, :utc_datetime)
    end

    flush()

    %Postgrex.Result{rows: rows} =
      Ecto.Adapters.SQL.query!(
        Mobilizon.Storage.Repo,
        "SELECT id, role FROM members"
      )

    Enum.each(rows, fn [id, role] ->
      if role in ["member", "moderator", "administrator", "creator"] do
        Ecto.Adapters.SQL.query!(
          Mobilizon.Storage.Repo,
          "UPDATE members SET member_since = '#{DateTime.to_iso8601(DateTime.utc_now())}' WHERE id = '#{
            Ecto.UUID.cast!(id)
          }'"
        )
      end
    end)
  end

  def down do
    alter table(:members) do
      remove(:member_since)
    end
  end
end
