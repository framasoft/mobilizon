defmodule Mobilizon.Repo.Migrations.MoveMemberRoleToEnum do
  use Ecto.Migration
  alias Mobilizon.Actors.MemberRole

  def up do
    MemberRole.create_type()

    alter table(:members) do
      add(:role_tmp, MemberRole.type(), default: "member")
    end

    execute("UPDATE members set role_tmp = 'member' where role = 0")
    execute("UPDATE members set role_tmp = 'moderator' where role = 1")
    execute("UPDATE members set role_tmp = 'creator' where role = 2")

    execute("UPDATE members set role_tmp = 'not_approved' where approved is false")

    alter table(:members) do
      remove(:role)
      remove(:approved)
    end

    rename(table(:members), :role_tmp, to: :role)
  end

  def down do
    alter table(:members) do
      add(:role_tmp, :integer, default: 0)
      add(:approved, :boolean, default: true)
    end

    execute("UPDATE members set approved = false where role = 'not_approved'")

    execute("UPDATE members set role_tmp = 0 where role = 'member' or role = 'not_approved'")
    execute("UPDATE members set role_tmp = 1 where role = 'moderator'")
    execute("UPDATE members set role_tmp = 2 where role = 'administrator' or role = 'creator'")

    alter table(:members) do
      remove(:role)
    end

    MemberRole.drop_type()

    rename(table(:members), :role_tmp, to: :role)
  end
end
