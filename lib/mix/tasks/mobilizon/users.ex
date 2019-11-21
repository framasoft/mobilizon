defmodule Mix.Tasks.Mobilizon.Users do
  @moduledoc """
  Tasks to manage users
  """
  use Mix.Task

  @shortdoc "Manages Mobilizon users"

  @impl Mix.Task
  def run(_) do
    Mix.shell().info("\nAvailable tasks:")
    Mix.Tasks.Help.run(["--search", "mobilizon.users."])
  end
end
