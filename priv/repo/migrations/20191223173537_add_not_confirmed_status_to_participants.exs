defmodule Mobilizon.Storage.Repo.Migrations.AddNotConfirmedStatusToParticipants do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    Ecto.Migration.execute("ALTER TYPE participant_role ADD VALUE IF NOT EXISTS 'not_confirmed'")
  end

  def down do
    IO.puts("Not removing value 'not_confirmed' from participant_role type")
  end
end
