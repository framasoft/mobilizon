defmodule Mobilizon.Service.GitStatus do
  @moduledoc """
  See https://github.com/CrowdHailer/git_status/
  """
  require Logger

  @commit (case System.cmd("git", ["describe", "--tags", "--dirty"]) do
             {hash, 0} ->
               String.trim(hash)

             _ ->
               Logger.warn("Could not read git commit hash")
               "UNKNOWN"
           end)

  @doc """
  The git commit hash read at compile time, if present
  """
  @spec commit :: String.t()
  def commit, do: @commit
end
