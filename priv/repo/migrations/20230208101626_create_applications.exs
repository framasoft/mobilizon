defmodule Mobilizon.Repo.Migrations.CreateApplications do
  use Ecto.Migration

  def change do
    create table(:applications) do
      add(:name, :string, null: false)
      add(:client_id, :string, null: false)
      add(:client_secret, :string, null: false)
      add(:redirect_uris, :string, null: false)
      add(:scopes, :string, null: true)
      add(:website, :string, null: true)
      add(:owner_type, :string, null: true)
      add(:owner_id, :integer, null: true)

      timestamps()
    end

    create(index(:applications, [:owner_id, :owner_type]))
  end
end
