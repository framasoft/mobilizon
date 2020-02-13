defmodule Mobilizon.Storage.Repo.Migrations.UpgradeObanJobsToV8 do
  use Ecto.Migration

  def up, do: Oban.Migrations.up(version: 8)
  def down, do: Oban.Migrations.down()
end
