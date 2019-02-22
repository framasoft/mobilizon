defmodule Mobilizon.Repo.Migrations.MakeFollowerTableUnique do
  use Ecto.Migration

  def up do
    create(
      unique_index(:followers, [:actor_id, :target_actor_id],
        name: :followers_actor_target_actor_unique_index
      )
    )
  end

  def down do
    drop(
      index(:followers, [:actor_id, :target_actor_id],
        name: :followers_actor_target_actor_unique_index
      )
    )
  end
end
