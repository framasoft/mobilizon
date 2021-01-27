defmodule Mobilizon.Storage.Repo.Migrations.UpgradeObanJobsToV10 do
  use Ecto.Migration

  defdelegate up, to: Oban.Migrations
  defdelegate down, to: Oban.Migrations
end
