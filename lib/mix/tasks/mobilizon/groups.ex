defmodule Mix.Tasks.Mobilizon.Groups do
  @moduledoc """
  Tasks to manage groups
  """

  use Mix.Task

  alias Mix.Tasks

  @shortdoc "Manages Mobilizon groups"

  @impl Mix.Task
  def run(_) do
    Mix.shell().info("\nAvailable tasks:")
    Tasks.Help.run(["--search", "mobilizon.groups."])
  end
end
