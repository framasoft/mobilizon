defmodule Mobilizon.Repo.Migrations.FusionPublicPrivateKeyIntoKeysColumn do
  use Ecto.Migration

  def up do
    rename(table(:actors), :private_key, to: :keys)

    alter table(:actors) do
      remove(:public_key)
    end
  end

  def down do
    alter table(:actors) do
      rename(:keys, to: :private_key)
      add(:public_key, :text, null: true)
    end
  end
end
