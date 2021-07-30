defmodule Mobilizon.Storage.Repo.Migrations.PutUniqueIndexOnParticipantsUrls do
  use Ecto.Migration

  def up do
    create_if_not_exists(unique_index("participants", [:url]))
  end

  def down do
    drop_if_exists(index("participants", [:url]))
  end
end
