defmodule Mix.Tasks.Mobilizon.Actors do
  @moduledoc """
  Tasks to manage actors
  """

  use Mix.Task

  alias Mix.Tasks

  @shortdoc "Manages Mobilizon actors"

  @impl Mix.Task
  def run(_) do
    Mix.shell().info("\nAvailable tasks:")
    Tasks.Help.run(["--search", "mobilizon.actors."])
  end
end
