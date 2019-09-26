# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/mix/tasks/pleroma/relay.ex

defmodule Mix.Tasks.Mobilizon.Relay do
  @moduledoc """
  Manages remote relays

  ## Follow a remote relay

  ``mix mobilizon.relay follow <relay_url>``

  Example: ``mix mobilizon.relay follow  https://example.org/relay``

  ## Unfollow a remote relay

  ``mix mobilizon.relay unfollow <relay_url>``

  Example: ``mix mobilizon.relay unfollow https://example.org/relay``
  """

  use Mix.Task

  alias Mix.Tasks.Mobilizon.Common
  alias Mobilizon.Service.ActivityPub.Relay

  @shortdoc "Manages remote relays"
  def run(["follow", target]) do
    Common.start_mobilizon()

    case Relay.follow(target) do
      {:ok, _activity} ->
        # put this task to sleep to allow the genserver to push out the messages
        :timer.sleep(500)

      {:error, e} ->
        IO.puts(:stderr, "Error while following #{target}: #{inspect(e)}")
    end
  end

  def run(["unfollow", target]) do
    Common.start_mobilizon()

    case Relay.unfollow(target) do
      {:ok, _activity} ->
        # put this task to sleep to allow the genserver to push out the messages
        :timer.sleep(500)

      {:error, e} ->
        IO.puts(:stderr, "Error while unfollowing #{target}: #{inspect(e)}")
    end
  end

  def run(["accept", target]) do
    Common.start_mobilizon()

    case Relay.accept(target) do
      {:ok, _activity} ->
        # put this task to sleep to allow the genserver to push out the messages
        :timer.sleep(500)

      {:error, e} ->
        IO.puts(:stderr, "Error while accept #{target} follow: #{inspect(e)}")
    end
  end
end
