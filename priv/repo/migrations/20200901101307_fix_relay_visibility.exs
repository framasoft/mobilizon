defmodule Mobilizon.Storage.Repo.Migrations.FixRelayVisibility do
  use Ecto.Migration
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Storage.Repo
  import Ecto.Query

  def up do
    Actor
    |> where(preferred_username: "relay")
    |> where(type: "Application")
    |> where([a], is_nil(a.domain))
    |> update(set: [visibility: "public"])
    |> Repo.update_all([])
  end

  def down do
    IO.puts("Not changing Relay visibility back")
  end
end
