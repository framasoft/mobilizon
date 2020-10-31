# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.CLI do
  @moduledoc """
  CLI wrapper for releases
  """
  alias Mix.Tasks.Mobilizon.Ecto.{Migrate, Rollback}

  def run(args) do
    [task | args] = String.split(args)

    case task do
      "migrate" -> migrate(args)
      "rollback" -> rollback(args)
      task -> mix_task(task, args)
    end
  end

  defp mix_task(task, args) do
    Application.load(:mobilizon)
    {:ok, modules} = :application.get_key(:mobilizon, :modules)

    module =
      Enum.find(modules, fn module ->
        module = Module.split(module)

        case module do
          ["Mix", "Tasks", "Mobilizon" | rest] ->
            String.downcase(Enum.join(rest, ".")) == task

          _ ->
            false
        end
      end)

    if module do
      module.run(args)
    else
      IO.puts("The task #{task} does not exist")
    end
  end

  def migrate(args) do
    Migrate.run(args)
  end

  def rollback(args) do
    Rollback.run(args)
  end
end
