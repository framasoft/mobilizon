defmodule Mobilizon.Repo.Migrations.MoveParticipantRoleToEnum do
  use Ecto.Migration
  alias Mobilizon.Events.ParticipantRole

  def up do
    ParticipantRole.create_type()

    alter table(:participants) do
      add(:role_tmp, ParticipantRole.type(), default: "participant")
    end

    execute("UPDATE participants set role_tmp = 'not_approved' where role = 0")
    execute("UPDATE participants set role_tmp = 'participant' where role = 1")
    execute("UPDATE participants set role_tmp = 'moderator' where role = 2")
    execute("UPDATE participants set role_tmp = 'administrator' where role = 3")
    execute("UPDATE participants set role_tmp = 'creator' where role = 4")

    alter table(:participants) do
      remove(:role)
    end

    rename(table(:participants), :role_tmp, to: :role)
  end

  def down do
    alter table(:participants) do
      add(:role_tmp, :integer, default: 1)
    end

    execute("UPDATE participants set role_tmp = 0 where role = 'not_approved'")
    execute("UPDATE participants set role_tmp = 1 where role = 'participant'")
    execute("UPDATE participants set role_tmp = 2 where role = 'moderator'")
    execute("UPDATE participants set role_tmp = 3 where role = 'administrator'")
    execute("UPDATE participants set role_tmp = 4 where role = 'creator'")

    alter table(:participants) do
      remove(:role)
    end

    ParticipantRole.drop_type()

    rename(table(:participants), :role_tmp, to: :role)
  end
end
