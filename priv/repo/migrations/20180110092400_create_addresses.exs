defmodule Mobilizon.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add(:description, :string)
      add(:floor, :string)
      add(:addressCountry, :string)
      add(:addressLocality, :string)
      add(:addressRegion, :string)
      add(:postalCode, :string)
      add(:streetAddress, :string)
      add(:geom, :geometry)

      timestamps()
    end
  end
end
