defmodule Mobilizon.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add(:name, :string)
      add(:description, :text)
      add(:color, :string)

      add(:event_id, references(:events, on_delete: :delete_all), null: false)

      timestamps()
    end
  end
end
