defmodule Mobilizon.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resource, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:title, :string, null: false)
      add(:url, :string, null: false)
      add(:type, :integer, null: false)
      add(:summary, :text)
      add(:resource_url, :string)
      add(:metadata, :map)
      add(:path, :string, null: false)

      add(:parent_id, references(:resource, on_delete: :delete_all, type: :uuid), null: true)

      add(:actor_id, references(:actors, on_delete: :delete_all), null: false)
      add(:creator_id, references(:actors, on_delete: :nilify_all), null: true)

      timestamps()
    end
  end
end
