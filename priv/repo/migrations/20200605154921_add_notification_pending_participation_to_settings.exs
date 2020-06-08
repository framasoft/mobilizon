defmodule Mobilizon.Storage.Repo.Migrations.AddNotificationPendingParticipationToSettings do
  use Ecto.Migration

  def change do
    alter table(:user_settings) do
      add(:notification_pending_participation, :integer, default: 5)
    end
  end
end
