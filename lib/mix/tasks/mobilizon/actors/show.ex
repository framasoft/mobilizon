defmodule Mix.Tasks.Mobilizon.Actors.Show do
  @moduledoc """
  Task to display an actor details
  """
  use Mix.Task
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor

  @shortdoc "Show a Mobilizon user details"

  @impl Mix.Task
  def run([preferred_username]) do
    Mix.Task.run("app.start")

    case {:actor, Actors.get_actor_by_name_with_preload(preferred_username)} do
      {:actor, %Actor{} = actor} ->
        Mix.shell().info("""
        Informations for the actor #{actor.preferred_username}:
          - Type: #{actor.type}
          - Domain: #{if is_nil(actor.domain), do: "Local", else: actor.domain}
          - Name: #{actor.name}
          - Summary: #{actor.summary}
          - User: #{if is_nil(actor.user), do: "Remote", else: actor.user.email}
        """)

      {:actor, nil} ->
        Mix.raise("Error: No such actor")
    end
  end

  def run(_) do
    Mix.raise("mobilizon.actors.show requires an username as argument")
  end
end
