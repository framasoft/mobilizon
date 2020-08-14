defmodule Mobilizon.Storage.Repo.Migrations.AddPublishedAtToEntities do
  use Ecto.Migration
  alias Mobilizon.Storage.Repo
  import Ecto.Query

  def up do
    alter table(:comments) do
      add(:published_at, :utc_datetime)
    end

    flush()

    copy_published_at_from_inserted_at("comments")

    alter table(:resource) do
      add(:published_at, :utc_datetime)
    end

    flush()

    copy_published_at_from_inserted_at("resource")

    alter table(:todo_lists) do
      add(:published_at, :utc_datetime)
    end

    flush()

    copy_published_at_from_inserted_at("todo_lists")

    alter table(:todos) do
      add(:published_at, :utc_datetime)
    end

    flush()

    copy_published_at_from_inserted_at("todos")
  end

  def down do
    alter table(:comments) do
      remove(:published_at)
    end

    alter table(:resource) do
      remove(:published_at)
    end

    alter table(:todo_lists) do
      remove(:published_at)
    end

    alter table(:todos) do
      remove(:published_at)
    end
  end

  @spec copy_published_at_from_inserted_at(String.t()) :: any()
  defp copy_published_at_from_inserted_at(table_name) do
    from(c in table_name,
      update: [set: [published_at: c.inserted_at]]
    )
    |> Repo.update_all([])
  end
end
