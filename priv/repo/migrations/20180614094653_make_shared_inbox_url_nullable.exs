defmodule Mobilizon.Repo.Migrations.MakeSharedInboxUrlNullable do
  use Ecto.Migration

  def up do
    alter table(:actors) do
      modify(:shared_inbox_url, :string, null: true, default: nil)
    end
  end

  def down do
    alter table(:actors) do
      add(:shared_inbox_url, :string, null: false, default: "")
    end
  end
end
