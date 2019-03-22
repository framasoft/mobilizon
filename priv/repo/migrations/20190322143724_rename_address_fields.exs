defmodule Mobilizon.Repo.Migrations.RenameAddressFields do
  use Ecto.Migration

  def change do
    rename(table(:addresses), :addressCountry, to: :country)
    rename(table(:addresses), :addressLocality, to: :locality)
    rename(table(:addresses), :addressRegion, to: :region)
    rename(table(:addresses), :postalCode, to: :postal_code)
    rename(table(:addresses), :streetAddress, to: :street)
  end
end
