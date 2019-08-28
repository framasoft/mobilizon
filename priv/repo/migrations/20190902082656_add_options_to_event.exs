defmodule Mobilizon.Repo.Migrations.AddOptionsToEvent do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:options, :map)
    end
  end
end
