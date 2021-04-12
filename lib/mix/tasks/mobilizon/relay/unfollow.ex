defmodule Mix.Tasks.Mobilizon.Relay.Unfollow do
  @moduledoc """
  Task to unfollow an instance
  """
  use Mix.Task
  alias Mobilizon.Federation.ActivityPub.Relay
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Unfollow an instance"

  @impl Mix.Task
  def run([target]) do
    start_mobilizon()

    case Relay.unfollow(target) do
      {:ok, _activity, _follow} ->
        # put this task to sleep to allow the genserver to push out the messages
        :timer.sleep(500)
        shell_info("Unfollowed #{target}")

      {:error, e} ->
        shell_error("Error while unfollowing #{target}: #{inspect(e)}")
    end
  end

  def run(_) do
    shell_error("mobilizon.relay.unfollow requires an instance hostname as arguments")
  end
end
