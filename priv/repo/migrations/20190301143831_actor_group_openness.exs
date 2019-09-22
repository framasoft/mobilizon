defmodule Mobilizon.Repo.Migrations.ActorGroupOpenness do
  use Ecto.Migration
  alias Mobilizon.Actors.ActorOpenness

  def up do
    ActorOpenness.create_type()

    alter table(:actors) do
      add(:openness, ActorOpenness.type(), default: "moderated")
    end
  end

  def down do
    alter table(:actors) do
      remove(:openness)
    end
  end
end
