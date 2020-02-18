defmodule Mobilizon.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todo_lists, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:title, :string)
      add(:url, :string)
      add(:actor_id, references(:actors, on_delete: :delete_all), null: false)

      timestamps()
    end

    create table(:todos, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:title, :string)
      add(:url, :string)
      add(:status, :boolean, default: false, null: false)
      add(:due_date, :utc_datetime)
      add(:creator_id, references(:actors, on_delete: :delete_all), null: false)
      add(:assigned_to_id, references(:actors, on_delete: :nilify_all))

      add(:todo_list_id, references(:todo_lists, on_delete: :delete_all, type: :uuid), null: false)

      timestamps()
    end
  end
end
