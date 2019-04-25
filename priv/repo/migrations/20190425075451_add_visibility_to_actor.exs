defmodule Mobilizon.Repo.Migrations.AddVisibilityToActor do
  use Ecto.Migration

  alias Mobilizon.Actors.ActorVisibilityEnum

  def up do
    ActorVisibilityEnum.create_type()

    alter table(:actors) do
      add(:visibility, ActorVisibilityEnum.type(), default: "private")
    end
  end

  def down do
    alter table(:actors) do
      remove(:visibility)
    end

    ActorVisibilityEnum.drop_type()
  end
end
