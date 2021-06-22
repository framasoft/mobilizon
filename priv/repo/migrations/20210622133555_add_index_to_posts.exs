defmodule Mobilizon.Storage.Repo.Migrations.AddIndexToPosts do
  use Ecto.Migration

  def up do
    create_if_not_exists(unique_index("posts", [:url]))
  end

  def down do
    drop_if_exists(index("posts", [:url]))
  end
end
