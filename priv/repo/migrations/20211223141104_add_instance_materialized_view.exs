defmodule Mobilizon.Storage.Repo.Migrations.AddInstanceMaterializedView do
  use Ecto.Migration
  alias Mobilizon.Storage.Views.Instances

  def up do
    execute(Instances.create_materialized_view())

    execute(Instances.refresh_instances())

    execute(Instances.drop_trigger())

    execute(Instances.create_trigger())

    create_if_not_exists(unique_index("instances", [:domain]))
  end

  def down do
    drop_if_exists(unique_index("instances", [:domain]))

    execute(Instances.drop_refresh_instances())

    execute(Instances.drop_view())
  end
end
