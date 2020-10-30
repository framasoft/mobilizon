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

  alias Mix.Tasks
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Manages remote relays"

  @impl Mix.Task
  def run(_) do
    shell_info("\nAvailable tasks:")

    if mix_shell?() do
      Tasks.Help.run(["--search", "mobilizon.relay."])
    else
      show_subtasks_for_module(__MODULE__)
    end
  end
end
