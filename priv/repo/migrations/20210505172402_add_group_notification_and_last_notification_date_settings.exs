defmodule Mobilizon.Storage.Repo.Migrations.AddGroupNotificationAndLastNotificationDateSettings do
  use Ecto.Migration

  def change do
    alter table(:user_settings) do
      add(:group_notifications, :integer, default: 10, null: false)
      add(:last_notification_sent, :utc_datetime, null: true)
    end
  end
end
