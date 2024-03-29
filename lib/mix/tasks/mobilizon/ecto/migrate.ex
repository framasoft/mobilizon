# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Mobilizon.Ecto.Migrate do
  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  alias Mix.Tasks.Mobilizon.Ecto, as: EctoTask
  require Logger

  @shortdoc "Wrapper on `ecto.migrate` task."

  @aliases [
    n: :step,
    v: :to
  ]

  @switches [
    all: :boolean,
    step: :integer,
    to: :integer,
    quiet: :boolean,
    log_sql: :boolean,
    strict_version_order: :boolean,
    migrations_path: :string
  ]

  @app :mobilizon
  @repo Mobilizon.Storage.Repo
  @start_apps [:logger, :ssl, :postgrex, :ecto]

  @moduledoc """
  Changes `Logger` level to `:info` before start migration.
  Changes level back when migration ends.

  ## Start migration

      mix mobilizon.ecto.migrate [OPTIONS]

  Options:
    - see https://hexdocs.pm/ecto_sql/Mix.Tasks.Ecto.Migrate.html
  """

  @impl true
  def run(args \\ []) do
    load_app()
    {opts, _} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

    if Application.get_env(:mobilizon, @repo)[:ssl] do
      Application.ensure_all_started(:ssl)
    end

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :all, true)

    opts =
      if opts[:quiet],
        do: Keyword.merge(opts, log: false, log_sql: false),
        else: opts

    path = EctoTask.ensure_migrations_path(@repo, opts)

    level = Logger.level()
    Logger.configure(level: :info)

    {:ok, _, _} = Ecto.Migrator.with_repo(@repo, &Ecto.Migrator.run(&1, path, :up, opts))

    Logger.configure(level: level)
  end

  defp load_app do
    IO.puts("Loading app..")
    Application.load(@app)
    IO.puts("Starting dependencies..")
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    if mix_task?(), do: Mix.Task.run("app.config")
  end
end
