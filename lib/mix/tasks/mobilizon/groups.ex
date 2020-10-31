defmodule Mix.Tasks.Mobilizon.Groups do
  @moduledoc """
  Tasks to manage groups
  """

  use Mix.Task

  alias Mix.Tasks
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Manages Mobilizon groups"

  @impl Mix.Task
  def run(_) do
    shell_info("\nAvailable tasks:")
    Tasks.Help.run(["--search", "mobilizon.groups."])
  end
end
