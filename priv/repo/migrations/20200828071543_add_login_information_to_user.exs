defmodule Mobilizon.Storage.Repo.Migrations.AddLoginInformationToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:last_sign_in_at, :utc_datetime, null: true)
      add(:last_sign_in_ip, :string, null: true)
      add(:current_sign_in_ip, :string, null: true)
      add(:current_sign_in_at, :utc_datetime, null: true)
    end
  end
end
