defmodule Mobilizon.Repo.Migrations.CreateUserPushSubscriptions do
  use Ecto.Migration

  def change do
    create table(:user_push_subscriptions, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:digest, :text, null: false)
      add(:endpoint, :string, null: false)
      add(:auth, :string, null: false)
      add(:p256dh, :string, null: false)

      timestamps()
    end

    create(unique_index(:user_push_subscriptions, [:user_id, :digest]))
  end
end
