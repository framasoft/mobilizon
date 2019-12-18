defmodule Mix.Tasks.Mobilizon.Actors do
  @moduledoc """
  Tasks to manage actors
  """
  use Mix.Task

  @shortdoc "Manages Mobilizon actors"

  @impl Mix.Task
  def run(_) do
    Mix.shell().info("\nAvailable tasks:")
    Mix.Tasks.Help.run(["--search", "mobilizon.actors."])
  end
end
