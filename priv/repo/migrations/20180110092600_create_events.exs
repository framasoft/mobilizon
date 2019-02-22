defmodule Mobilizon.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add(:title, :string, null: false)
      add(:slug, :string, null: false)
      add(:description, :string, null: true)
      add(:begins_on, :datetimetz)
      add(:ends_on, :datetimetz)
      add(:state, :integer, null: false)
      add(:public, :boolean, null: false)
      add(:status, :integer, null: false)
      add(:large_image, :string)
      add(:thumbnail, :string)
      add(:publish_at, :datetimetz)
      add(:organizer_account_id, references(:accounts, on_delete: :nothing))
      add(:organizer_group_id, references(:groups, on_delete: :nothing))
      add(:category_id, references(:categories, on_delete: :nothing), null: false)
      add(:address_id, references(:addresses, on_delete: :delete_all))

      timestamps()
    end

    create(index(:events, [:organizer_account_id]))
    create(index(:events, [:organizer_group_id]))
    create(unique_index(:events, [:slug]))
  end
end
