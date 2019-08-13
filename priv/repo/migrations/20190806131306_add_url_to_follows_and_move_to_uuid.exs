defmodule Mobilizon.Repo.Migrations.AddUrlToFollowsAndMoveToUuid do
  use Ecto.Migration

  def up do
    alter table(:followers, primary_key: false) do
      remove(:score)
      remove(:id)
      add(:id, :uuid, primary_key: true)
      add(:url, :string, null: false)
    end
  end

  def down do
    alter table(:followers, primary_key: true) do
      add(:score, :integer, default: 1000)
      remove(:id)
      add(:id, :serial, primary_key: true)
      remove(:url)
    end
  end
end
