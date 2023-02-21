defmodule Mobilizon.Storage.Repo.Migrations.AddDeviceFlowSupport do
  use Ecto.Migration

  def change do
    alter table(:application_tokens) do
      add(:status, :string, default: :pending, null: false)
      add(:scope, :string)
    end
  end
end
