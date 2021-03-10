defmodule Mobilizon.Storage.Repo.Migrations.AddIndexesToActivities do
  use Ecto.Migration

  def change do
    create(index(:activities, [:group_id], name: "activity_group_id"))
    create(index(:activities, [:author_id, :type], name: "activity_filter"))
  end
end
