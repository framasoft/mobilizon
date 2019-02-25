defmodule Mobilizon.Repo.Migrations.DropCategories do
  use Ecto.Migration

  def up do
    # The category field is a string for the time being
    # while we determine the definitive minimal list of
    # categories in https://framagit.org/framasoft/mobilizon/issues/30
    # afterwards it will be a PostgreSQL enum and we'll
    # just add new elements without being able to delete
    # the previous ones
    alter table(:events) do
      add(:category, :string)
      remove(:category_id)
    end

    drop(table(:categories))
  end

  def down do
    create table(:categories) do
      add(:title, :string)
      add(:description, :string)
      add(:picture, :string)

      timestamps()
    end

    create(unique_index(:categories, [:title]))

    alter table(:events) do
      remove(:category)
      add(:category_id, references(:categories, on_delete: :nothing))
    end
  end
end
