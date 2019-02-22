defmodule :"Elixir.Mobilizon.Repo.Migrations.Add-user-password-reset-fields" do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add(:reset_password_sent_at, :utc_datetime)
      add(:reset_password_token, :string)
    end

    create(
      unique_index(:users, [:reset_password_token],
        name: "index_unique_users_reset_password_token"
      )
    )
  end

  def down do
    alter table(:users) do
      remove(:reset_password_sent_at)
      remove(:reset_password_token)
    end
  end
end
