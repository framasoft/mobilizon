defmodule Mobilizon.Storage.Repo.Migrations.RepairRelayAndAnonymousActors do
  use Ecto.Migration

  def up do
    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "UPDATE actors SET manually_approves_followers = true WHERE preferred_username = 'relay' and domain is null"
    )

    Ecto.Adapters.SQL.query!(
      Mobilizon.Storage.Repo,
      "UPDATE actors SET manually_approves_followers = true WHERE preferred_username = 'anonymous' and domain is null"
    )
  end
end
