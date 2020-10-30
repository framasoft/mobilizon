defmodule Mix.Tasks.Mobilizon.Relay.Accept do
  @moduledoc """
  Task to accept an instance follow request
  """
  use Mix.Task
  alias Mobilizon.Federation.ActivityPub.Relay
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Accept an instance follow request"

  @impl Mix.Task
  def run([target]) do
    start_mobilizon()

    case Relay.accept(target) do
      {:ok, _activity} ->
        # put this task to sleep to allow the genserver to push out the messages
        :timer.sleep(500)

      {:error, e} ->
        IO.puts(:stderr, "Error while accept #{target} follow: #{inspect(e)}")
    end
  end

  def run(_) do
    shell_error("mobilizon.relay.accept requires an instance hostname as arguments")
  end
end
