defmodule Mobilizon.Repo.Migrations.MakeActorPublicKeyNullable do
  use Ecto.Migration

  def up do
    alter table(:actors) do
      modify(:public_key, :text, null: true)
    end
  end

  def down do
    alter table(:actors) do
      modify(:public_key, :text, null: false)
    end
  end
end
