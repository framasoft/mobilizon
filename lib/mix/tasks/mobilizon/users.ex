defmodule Mix.Tasks.Mobilizon.Users do
  @moduledoc """
  Tasks to manage users
  """

  use Mix.Task

  alias Mix.Tasks

  @shortdoc "Manages Mobilizon users"

  @impl Mix.Task
  def run(_) do
    Mix.shell().info("\nAvailable tasks:")
    Tasks.Help.run(["--search", "mobilizon.users."])
  end
end
