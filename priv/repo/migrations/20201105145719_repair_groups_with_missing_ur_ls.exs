defmodule Mobilizon.Storage.Repo.Migrations.RepairGroupsWithMissingURLs do
  use Ecto.Migration
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Storage.Repo
  import Ecto.{Changeset, Query}

  def up do
    Actor
    |> where([a], a.type == :Group and is_nil(a.domain))
    |> Repo.all()
    |> Enum.each(&fix_group/1)
  end

  def down do
    IO.puts("Nothing to revert here, this is a repair step.")
  end

  defp fix_group(%Actor{type: :Group, domain: nil, url: url} = group) do
    group
    |> change(%{})
    |> put_change(:resources_url, "#{url}/resources")
    |> put_change(:todos_url, "#{url}/todos")
    |> put_change(:posts_url, "#{url}/posts")
    |> put_change(:events_url, "#{url}/events")
    |> put_change(:discussions_url, "#{url}/discussions")
    |> Repo.update()
  end
end
