defmodule Mix.Tasks.Mobilizon.Relay.Follow do
  @moduledoc """
  Task to follow an instance
  """
  use Mix.Task
  alias Mobilizon.Federation.ActivityPub.Relay
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Follow an instance"

  @impl Mix.Task
  def run([target]) do
    start_mobilizon()

    case Relay.follow(target) do
      {:ok, _activity, _follow} ->
        # put this task to sleep to allow the genserver to push out the messages
        :timer.sleep(500)
        shell_info("Requested to follow #{target}")

      {:error, e} ->
        shell_error("Error while following #{target}: #{inspect(e)}")
    end
  end

  def run(_) do
    shell_error("mobilizon.relay.follow requires an instance hostname as arguments")
  end
end
