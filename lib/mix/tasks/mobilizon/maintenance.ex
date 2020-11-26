defmodule Mix.Tasks.Mobilizon.Maintenance do
  @moduledoc """
  Tasks to maintain mobilizon
  """

  use Mix.Task

  alias Mix.Tasks
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "List common Mobilizon maintenance tasks"

  @impl Mix.Task
  def run(_) do
    shell_info("\nAvailable tasks:")

    if mix_shell?() do
      Tasks.Help.run(["--search", "mobilizon.maintenance."])
    else
      show_subtasks_for_module(__MODULE__)
    end
  end
end
