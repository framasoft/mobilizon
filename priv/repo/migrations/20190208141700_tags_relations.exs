defmodule Mobilizon.Repo.Migrations.TagsRelations do
  use Ecto.Migration

  def up do
    create table(:tag_relations, primary_key: false) do
      add(:tag_id, references(:tags, on_delete: :delete_all), null: false, primary_key: true)
      add(:link_id, references(:tags, on_delete: :delete_all), null: false, primary_key: true)
      add(:weight, :integer, null: false, default: 1)
    end

    create(constraint(:tag_relations, :no_self_loops_check, check: "tag_id <> link_id"))
    create(index(:tag_relations, [:tag_id], name: :index_tag_relations_tag_id))
    create(index(:tag_relations, [:link_id], name: :index_tag_relations_link_id))
  end

  def down do
    drop(constraint(:tag_relations, :no_self_loops_check))

    drop(index(:tag_relations, [:tags_id]))
    drop(index(:tag_relations, [:link_id]))
    drop(table(:tag_relations))
  end
end
