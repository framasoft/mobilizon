defmodule Mobilizon.Repo.Migrations.SplitEventVisibilityAndJoinOptions do
  use Ecto.Migration
  alias Mobilizon.Events.EventVisibilityEnum
  alias Mobilizon.Events.JoinOptionsEnum

  @doc """
  EventVisibilityEnum has dropped some possible values, so we need to recreate it
  """
  def up do
    execute "ALTER TABLE events ALTER COLUMN visibility TYPE VARCHAR USING visibility::text"
    EventVisibilityEnum.drop_type
    EventVisibilityEnum.create_type
    execute "ALTER TABLE events ALTER COLUMN visibility TYPE event_visibility_type USING visibility::event_visibility_type"

    JoinOptionsEnum.create_type
    alter table(:events) do
      add(:join_options, JoinOptionsEnum.type(), null: false, default: "free")
    end
  end

  def down do
    alter table(:events) do
      remove(:join_options)
    end
    JoinOptionsEnum.drop_type

    execute "ALTER TABLE events ALTER COLUMN visibility TYPE VARCHAR USING visibility::text"
    EventVisibilityEnum.drop_type
    EventVisibilityEnum.create_type
    execute "ALTER TABLE events ALTER COLUMN visibility TYPE event_visibility_type USING visibility::event_visibility_type"
  end
end
