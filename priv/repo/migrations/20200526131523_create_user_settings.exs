defmodule Mobilizon.Repo.Migrations.CreateUserSettings do
  use Ecto.Migration

  def change do
    create table(:user_settings, primary_key: false) do
      add(:timezone, :string)
      add(:notification_on_day, :boolean)
      add(:notification_each_week, :boolean)
      add(:notification_before_event, :boolean)
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)

      timestamps()
    end
  end
end
