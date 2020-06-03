defmodule Mobilizon.Storage.Repo.Migrations.AddNewRolesToMember do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    Ecto.Migration.execute("ALTER TYPE member_role ADD VALUE IF NOT EXISTS 'invited'")
    Ecto.Migration.execute("ALTER TYPE member_role ADD VALUE IF NOT EXISTS 'rejected'")
  end

  def down do
    IO.puts("Not removing value 'invited' from member_role type")
    IO.puts("Not removing value 'rejected' from member_role type")
  end
end
