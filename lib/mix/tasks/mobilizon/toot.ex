defmodule Mix.Tasks.Mobilizon.Toot do
  @moduledoc """
  Creates a bot from a source
  """

  use Mix.Task
  require Logger

  @shortdoc "Toot to an user"
  def run([from, content]) do
    Mix.Task.run("app.start")

    with {:ok, _} <- MobilizonWeb.API.Comments.create_comment(from, content) do
      Mix.shell().info("Tooted")
    else
      {:local_actor, _} -> Mix.shell().error("Failed to toot.\nActor #{from} doesn't exist")
      _ -> Mix.shell().error("Failed to toot.")
    end
  end
end
