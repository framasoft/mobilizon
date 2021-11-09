# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Mobilizon.TzWorld.Update do
  use Mix.Task
  alias Mix.Tasks.TzWorld.Update, as: TzWorldUpdate
  import Mix.Tasks.Mobilizon.Common
  require Logger

  @shortdoc "Wrapper on `tz_world.update` task."

  @moduledoc """
  Changes `Logger` level to `:info` before downloading.
  Changes level back when downloads ends.

  ## Update TzWorld data

      mix mobilizon.tz_world.update
  """

  @impl true
  def run(_args) do
    start_mobilizon()

    level = Logger.level()
    Logger.configure(level: :info)

    TzWorldUpdate.run(nil)

    Logger.configure(level: level)
  end
end
