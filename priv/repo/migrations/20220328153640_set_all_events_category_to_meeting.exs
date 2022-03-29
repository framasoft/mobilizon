defmodule Mobilizon.Storage.Repo.Migrations.SetAllEventsCategoryToMeeting do
  use Ecto.Migration

  def up do
    Ecto.Migration.execute("UPDATE events SET category = 'MEETING'")
  end

  def down do
    Ecto.Migration.execute("UPDATE events SET category = 'meeting' WHERE category = 'MEETING'")
  end
end
