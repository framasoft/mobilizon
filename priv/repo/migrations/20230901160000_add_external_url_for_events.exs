defmodule Mobilizon.Storage.Repo.Migrations.AddExternalUrlForEvents do
  use Ecto.Migration
  alias Mobilizon.Events.JoinOptions

  def up do
    alter table(:events) do
      add(:external_participation_url, :string)
    end

    reset_join_options_enum()
  end

  def down do
    alter table(:events) do
      remove(:external_participation_url, :string)
    end

    reset_join_options_enum()
  end

  defp reset_join_options_enum do
    execute("ALTER TABLE events ALTER COLUMN join_options TYPE VARCHAR USING join_options::text")
    execute("ALTER TABLE events ALTER COLUMN join_options DROP DEFAULT")
    JoinOptions.drop_type()
    JoinOptions.create_type()

    execute(
      "ALTER TABLE events ALTER COLUMN join_options TYPE join_options USING join_options::join_options"
    )

    execute("ALTER TABLE events ALTER COLUMN join_options SET DEFAULT 'free'::join_options")
  end
end
