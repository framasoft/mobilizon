defmodule :"Elixir.Mobilizon.Repo.Migrations.Add-url-to-addresses" do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add(:url, :string, null: false)
    end
  end
end
