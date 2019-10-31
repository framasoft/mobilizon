defmodule Mix.Tasks.Mobilizon.Toot do
  @moduledoc """
  Creates a bot from a source.
  """

  use Mix.Task

  alias MobilizonWeb.API.Comments
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor

  require Logger

  @shortdoc "Toot to an user"
  def run([from, text]) do
    Mix.Task.run("app.start")

    with {:local_actor, %Actor{} = actor} <- {:local_actor, Actors.get_local_actor_by_name(from)},
         {:ok, _, _} <- Comments.create_comment(%{actor: actor, text: text}) do
      Mix.shell().info("Tooted")
    else
      {:local_actor, _, _} ->
        Mix.shell().error("Failed to toot.\nActor #{from} doesn't exist")

      _ ->
        Mix.shell().error("Failed to toot.")
    end
  end
end
