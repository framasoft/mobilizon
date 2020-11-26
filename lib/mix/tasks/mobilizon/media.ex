defmodule Mix.Tasks.Mobilizon.Media do
  @moduledoc """
  Tasks to manage media
  """

  use Mix.Task

  alias Mix.Tasks
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Manages Mobilizon media"

  @impl Mix.Task
  def run(_) do
    shell_info("\nAvailable tasks:")

    if mix_shell?() do
      Tasks.Help.run(["--search", "mobilizon.media."])
    else
      show_subtasks_for_module(__MODULE__)
    end
  end
end
