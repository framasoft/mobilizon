defmodule :"Elixir.Mobilizon.Repo.Migrations.Add-user-confirm-email-fields" do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add(:confirmed_at, :utc_datetime)
      add(:confirmation_sent_at, :utc_datetime)
      add(:confirmation_token, :string)
    end

    create(
      unique_index(:users, [:confirmation_token], name: "index_unique_users_confirmation_token")
    )
  end

  def down do
    alter table(:users) do
      remove(:confirmed_at)
      remove(:confirmation_sent_at)
      remove(:confirmation_token)
    end
  end
end
