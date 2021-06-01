defmodule Mobilizon.Storage.Repo.Migrations.AddIsAnnouncementToComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add(:is_announcement, :boolean, default: false, null: false)
    end
  end
end
