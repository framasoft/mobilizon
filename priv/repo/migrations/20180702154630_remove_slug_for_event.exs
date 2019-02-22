defmodule Mobilizon.Repo.Migrations.RemoveSlugForEvent do
  use Ecto.Migration

  def up do
    alter table(:events) do
      remove(:slug)
    end
  end

  def down do
    alter table(:events) do
      add(:slug, :string, null: false)
    end
  end
end
