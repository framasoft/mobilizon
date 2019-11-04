defmodule Mobilizon.Storage.Repo.Migrations.AddUniqueIndexOnActorAndEventForParticipant do
  use Ecto.Migration

  def change do
    create(unique_index(:participants, [:event_id, :actor_id]))
  end
end
