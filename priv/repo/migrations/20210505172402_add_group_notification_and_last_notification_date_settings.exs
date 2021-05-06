defmodule Mobilizon.Storage.Repo.Migrations.AddGroupNotificationAndLastNotificationDateSettings do
  use Ecto.Migration

  def change do
    alter table(:user_settings) do
      add(:group_notifications, :integer, default: 10, nullable: false)
      add(:last_notification_sent, :utc_datetime, nullable: true)
    end
  end
end
