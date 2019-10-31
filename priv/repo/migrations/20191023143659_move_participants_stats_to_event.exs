defmodule Mobilizon.Storage.Repo.Migrations.MoveParticipantsStatsToEvent do
  use Ecto.Migration

  def up do
    alter table(:events) do
      add(:participant_stats, :map)
    end
  end

  def down do
    alter table(:events) do
      remove(:participant_stats)
    end
  end
end
