# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-onl

defmodule Mix.Tasks.Mobilizon.Ecto do
  @moduledoc """
  Provides tools for Ecto-related tasks (such as migrations)
  """

  @doc """
  Ensures the given repository's migrations path exists on the file system.
  """
  @spec ensure_migrations_path(Ecto.Repo.t(), Keyword.t()) :: String.t()
  def ensure_migrations_path(repo, opts) do
    path = opts[:migrations_path] || Path.join(source_repo_priv(repo), "migrations")

    path =
      case Path.type(path) do
        :relative ->
          Path.join(Application.app_dir(:mobilizon), path)

        :absolute ->
          path
      end

    if not File.dir?(path) do
      raise_missing_migrations(Path.relative_to_cwd(path), repo)
    end

    path
  end

  @doc """
  Returns the private repository path relative to the source.
  """
  def source_repo_priv(repo) do
    config = repo.config()
    priv = config[:priv] || "priv/#{repo |> Module.split() |> List.last() |> Macro.underscore()}"
    Path.join(Application.app_dir(:mobilizon), priv)
  end

  defp raise_missing_migrations(path, repo) do
    raise("""
    Could not find migrations directory #{inspect(path)}
    for repo #{inspect(repo)}.
    This may be because you are in a new project and the
    migration directory has not been created yet. Creating an
    empty directory at the path above will fix this error.
    If you expected existing migrations to be found, please
    make sure your repository has been properly configured
    and the configured path exists.
    """)
  end
end
