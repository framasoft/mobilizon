defmodule Mobilizon.Storage.Repo.Migrations.AddNotifyToFollowers do
  use Ecto.Migration

  def change do
    alter table(:followers) do
      add(:notify, :boolean, default: true)
    end
  end
end
