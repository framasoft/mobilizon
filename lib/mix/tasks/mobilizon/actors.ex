defmodule Mix.Tasks.Mobilizon.Actors do
  @moduledoc """
  Tasks to manage actors
  """

  use Mix.Task

  alias Mix.Tasks
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Manages Mobilizon actors"

  @impl Mix.Task
  def run(_) do
    shell_info("\nAvailable tasks:")

    if mix_shell?() do
      Tasks.Help.run(["--search", "mobilizon.actors."])
    else
      show_subtasks_for_module(__MODULE__)
    end
  end
end
