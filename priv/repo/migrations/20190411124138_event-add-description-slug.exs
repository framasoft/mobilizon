defmodule Elixir.Mobilizon.Repo.Migrations.EventAddDescriptionSlug do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:slug, :string)
    end
  end
end
