defmodule Mobilizon.Repo.Migrations.AlterEventsSetDescriptionAsText do
  use Ecto.Migration

  def up do
    alter table(:events) do
      modify(:description, :text)
    end
  end

  def down do
    alter table(:events) do
      modify(:description, :string)
    end
  end
end
