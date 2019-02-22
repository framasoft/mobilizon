defmodule Mobilizon.Repo.Migrations.AllowMultipleAccountsForUser do
  use Ecto.Migration

  def up do
    alter table(:actors) do
      add(:user_id, references(:users, on_delete: :delete_all), null: true)
    end

    alter table(:users) do
      remove(:actor_id)
    end
  end

  def down do
    alter table(:users) do
      add(:actor_id, references(:actors, on_delete: :delete_all), null: false)
    end

    alter table(:actors) do
      remove(:user_id)
    end
  end
end
