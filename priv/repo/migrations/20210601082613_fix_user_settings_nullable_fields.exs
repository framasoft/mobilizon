defmodule Mobilizon.Storage.Repo.Migrations.FixUserSettingsNullableFields do
  use Ecto.Migration

  def change do
    alter table(:user_settings) do
      modify(:group_notifications, :integer, default: 10, null: false)
      modify(:last_notification_sent, :utc_datetime, null: true)
    end
  end
end
