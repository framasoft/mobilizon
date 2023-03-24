defmodule Mobilizon.Repo.Migrations.CreateApplicationDeviceActivation do
  use Ecto.Migration

  def change do
    create table(:application_device_activation) do
      add(:user_code, :string)
      add(:device_code, :string)
      add(:scope, :string)
      add(:expires_in, :integer)
      add(:status, :string, default: "pending")
      add(:user_id, references(:users, on_delete: :delete_all), null: true)
      add(:application_id, references(:applications, on_delete: :delete_all), null: false)
      timestamps()
    end
  end
end
