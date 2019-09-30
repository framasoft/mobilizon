defmodule Mobilizon.Storage.Repo.Migrations.AddRejectedToParticipantRole do
  use Ecto.Migration
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Events.Participant
  alias Mobilizon.Events.ParticipantRole
  import Ecto.Query

  @disable_ddl_transaction true

  def up do
    Ecto.Migration.execute(
      "ALTER TYPE #{ParticipantRole.type()} ADD VALUE IF NOT EXISTS 'rejected'"
    )
  end

  def down do
    Participant
    |> where(role: "rejected")
    |> Repo.delete_all()
  end
end
