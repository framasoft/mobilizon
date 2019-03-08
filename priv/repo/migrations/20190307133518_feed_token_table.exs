defmodule Mobilizon.Repo.Migrations.FeedTokenTable do
  use Ecto.Migration

  def change do
    create table(:feed_tokens, primary_key: false) do
      add(:token, Ecto.UUID.type(), primary_key: true)
      add(:actor_id, references(:actors, on_delete: :delete_all), null: true)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps(updated_at: false)
    end
  end
end
