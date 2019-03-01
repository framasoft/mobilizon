defmodule Mobilizon.Repo.Migrations.ActorGroupOpenness do
  use Ecto.Migration
  alias Mobilizon.Actors.ActorOpennessEnum

  def up do
    ActorOpennessEnum.create_type()

    alter table(:actors) do
      add(:openness, ActorOpennessEnum.type(), default: "moderated")
    end
  end

  def down do
    alter table(:actors) do
      remove(:openness)
    end
  end
end
