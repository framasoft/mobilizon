defmodule Mix.Tasks.Mobilizon.Relay.Refresh do
  @moduledoc """
  Task to refresh an instance details
  """
  use Mix.Task
  alias Mobilizon.Federation.ActivityPub.Relay
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Refresh an instance informations and crawl their outbox"

  @impl Mix.Task
  def run([target]) do
    start_mobilizon()
    IO.puts("Refreshing #{target}, this can take a while.")

    case Relay.refresh(target) do
      :ok ->
        IO.puts("Refreshed #{target}")

      err ->
        IO.puts(:stderr, "Error while refreshing #{target}: #{inspect(err)}")
    end
  end

  def run(_) do
    shell_error("mobilizon.relay.refresh requires an instance hostname as arguments")
  end
end
