defmodule Mobilizon.Repo.Migrations.MoveUserRoleToEnum do
  use Ecto.Migration

  alias Mobilizon.Users.UserRole

  def up do
    UserRole.create_type()

    alter table(:users) do
      add(:role_tmp, UserRole.type(), default: "user")
    end

    execute("UPDATE users set role_tmp = 'user' where role = 0")
    execute("UPDATE users set role_tmp = 'moderator' where role = 1")
    execute("UPDATE users set role_tmp = 'administrator' where role = 2")

    alter table(:users) do
      remove(:role)
    end

    rename(table(:users), :role_tmp, to: :role)
  end

  def down do
    alter table(:users) do
      add(:role_tmp, :integer, default: 0)
    end

    execute("UPDATE users set role_tmp = 0 where role = 'user'")
    execute("UPDATE users set role_tmp = 1 where role = 'moderator'")
    execute("UPDATE users set role_tmp = 2 where role = 'administrator'")

    alter table(:users) do
      remove(:role)
    end

    UserRole.drop_type()

    rename(table(:users), :role_tmp, to: :role)
  end
end
