defmodule Eventos.Repo.Migrations.AddUniqueConstraintOnParticipant do
  use Ecto.Migration

  def change do
    create unique_index(:participants, [:account_id, :event_id])
  end
end
