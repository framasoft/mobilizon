defmodule Mix.Tasks.Mobilizon.Groups.Refresh do
  @moduledoc """
  Task to refresh an actor details
  """
  use Mix.Task
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Refresher

  @shortdoc "Refresh a group private informations from an account member"

  @impl Mix.Task
  def run([group_url, on_behalf_of]) do
    Mix.Task.run("app.start")

    with %Actor{} = actor <- Actors.get_local_actor_by_name(on_behalf_of) do
      res = Refresher.fetch_group(group_url, actor)
      IO.puts(inspect(res))
    end
  end

  def run(_) do
    Mix.raise(
      "mobilizon.groups.refresh requires a group URL and an actor username which is member of the group as arguments"
    )
  end
end
