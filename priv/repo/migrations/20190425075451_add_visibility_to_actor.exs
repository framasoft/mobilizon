defmodule Mobilizon.Repo.Migrations.AddVisibilityToActor do
  use Ecto.Migration

  alias Mobilizon.Actors.ActorVisibility

  def up do
    ActorVisibility.create_type()

    alter table(:actors) do
      add(:visibility, ActorVisibility.type(), default: "private")
    end
  end

  def down do
    alter table(:actors) do
      remove(:visibility)
    end

    ActorVisibility.drop_type()
  end
end
