defmodule Mix.Tasks.Mobilizon.Users do
  @moduledoc """
  Tasks to manage users
  """

  use Mix.Task

  alias Mix.Tasks
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Manages Mobilizon users"

  @impl Mix.Task
  def run(_) do
    shell_info("\nAvailable tasks:")

    if mix_shell?() do
      Tasks.Help.run(["--search", "mobilizon.users."])
    else
      show_subtasks_for_module(__MODULE__)
    end
  end
end
