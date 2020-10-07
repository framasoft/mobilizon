defmodule Mobilizon.Storage.Repo.Migrations.ChangeDefaultNotificationPendingParticipation do
  use Ecto.Migration

  def up do
    alter table(:user_settings) do
      modify(:notification_pending_participation, :integer, default: 10)
    end
  end

  def down do
    alter table(:user_settings) do
      modify(:notification_pending_participation, :integer, default: 5)
    end
  end
end
