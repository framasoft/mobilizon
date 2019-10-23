defmodule Mobilizon.Storage.Repo.Migrations.DeleteActorsCascadeToFollowers do
  use Ecto.Migration

  def up do
    drop(constraint(:followers, "followers_actor_id_fkey"))
    drop(constraint(:followers, "followers_target_actor_id_fkey"))

    alter table(:followers) do
      modify(:actor_id, references(:actors, on_delete: :delete_all))
      modify(:target_actor_id, references(:actors, on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:followers, "followers_actor_id_fkey"))
    drop(constraint(:followers, "followers_target_actor_id_fkey"))

    alter table(:followers) do
      modify(:actor_id, references(:actors, on_delete: :nothing))
      modify(:target_actor_id, references(:actors, on_delete: :nothing))
    end
  end
end
