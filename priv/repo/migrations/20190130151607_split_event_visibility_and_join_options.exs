defmodule Mobilizon.Repo.Migrations.SplitEventVisibilityAndJoinOptions do
  use Ecto.Migration
  alias Mobilizon.Events.EventVisibility
  alias Mobilizon.Events.JoinOptions

  @doc """
  EventVisibility has dropped some possible values, so we need to recreate it

  Visibility allowed nullable values previously
  """
  def up do
    execute("ALTER TABLE events ALTER COLUMN visibility TYPE VARCHAR USING visibility::text")
    EventVisibility.drop_type()
    EventVisibility.create_type()

    execute(
      "ALTER TABLE events ALTER COLUMN visibility TYPE event_visibility USING visibility::event_visibility"
    )

    JoinOptions.create_type()

    alter table(:events) do
      add(:join_options, JoinOptions.type(), null: false, default: "free")
    end

    execute("UPDATE events SET visibility = 'public' WHERE visibility IS NULL")

    alter table(:events) do
      modify(:visibility, EventVisibility.type(), null: false, default: "public")
    end
  end

  def down do
    alter table(:events) do
      remove(:join_options)
    end

    JoinOptions.drop_type()

    execute("ALTER TABLE events ALTER COLUMN visibility TYPE VARCHAR USING visibility::text")
    EventVisibility.drop_type()
    EventVisibility.create_type()

    execute(
      "ALTER TABLE events ALTER COLUMN visibility TYPE event_visibility USING visibility::event_visibility"
    )
  end
end
