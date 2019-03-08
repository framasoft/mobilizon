defmodule Mobilizon.Repo.Migrations.FeedTokenTable do
  use Ecto.Migration

  def change do
    create table(:feed_token, primary_key: false) do
      add(:token, :string, primary_key: true)
      add(:actor_id, references(:actors, on_delete: :delete_all), null: true)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps(updated_at: false)
    end
  end
end
