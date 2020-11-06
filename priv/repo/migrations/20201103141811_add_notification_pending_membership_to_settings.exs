defmodule Mobilizon.Storage.Repo.Migrations.AddNotificationPendingMembershipToSettings do
  use Ecto.Migration

  def change do
    alter table(:user_settings) do
      add(:notification_pending_membership, :integer, default: 10)
    end
  end
end
