defmodule :"Elixir.Mobilizon.Repo.Migrations.Attach-pictures-to-actors" do
  use Ecto.Migration

  def change do
    alter table(:pictures) do
      add(:actor_id, references(:actors, on_delete: :delete_all), null: false)
    end
  end
end
