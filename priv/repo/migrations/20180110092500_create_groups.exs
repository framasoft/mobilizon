defmodule Mobilizon.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add(:title, :string, null: false)
      add(:slug, :string, null: false)
      add(:description, :string)
      add(:suspended, :boolean, default: false, null: false)
      add(:url, :string)
      add(:uri, :string)
      add(:address_id, references(:addresses, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:groups, [:slug]))
  end
end
