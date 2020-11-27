defmodule Mix.Tasks.Mobilizon.Users.Clean do
  @moduledoc """
  Clean unconfirmed users
  """

  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.Service.CleanUnconfirmedUsers

  @shortdoc "Clean unconfirmed users from Mobilizon"
  @grace_period Mobilizon.Config.get([:instance, :unconfirmed_user_grace_period_hours], 48)

  @impl Mix.Task
  def run(options) do
    {options, [], []} =
      OptionParser.parse(
        options,
        strict: [
          dry_run: :boolean,
          days: :integer,
          verbose: :boolean
        ],
        aliases: [
          d: :days,
          v: :verbose
        ]
      )

    dry_run = Keyword.get(options, :dry_run, false)
    grace_period = Keyword.get(options, :days)
    grace_period = if is_nil(grace_period), do: @grace_period, else: grace_period * 24
    verbose = Keyword.get(options, :verbose, false)

    start_mobilizon()

    case CleanUnconfirmedUsers.clean(dry_run: dry_run, grace_period: grace_period) do
      {:ok, deleted_users} ->
        if length(deleted_users) > 0 do
          if dry_run or verbose do
            details(deleted_users, dry_run, verbose)
          end

          result(dry_run, length(deleted_users))
        else
          empty_result(dry_run)
        end

        :ok

      _err ->
        shell_error("Error while cleaning unconfirmed users")
    end
  end

  @spec details(list(Media.t()), boolean(), boolean()) :: :ok
  defp details(deleted_users, dry_run, verbose) do
    cond do
      dry_run ->
        shell_info("List of users that would have been deleted")

      verbose ->
        shell_info("List of users that have been deleted")
    end

    Enum.each(deleted_users, fn deleted_user ->
      shell_info(
        "ID: #{deleted_user.id}, Email: #{deleted_user.email}, Profile: @#{
          hd(deleted_user.actors).preferred_username
        }"
      )
    end)
  end

  @spec result(boolean(), boolean()) :: :ok
  defp result(dry_run, nb_deleted_users) do
    if dry_run do
      shell_info("#{nb_deleted_users} users would have been deleted")
    else
      shell_info("#{nb_deleted_users} users have been deleted")
    end
  end

  @spec empty_result(boolean()) :: :ok
  defp empty_result(dry_run) do
    if dry_run do
      shell_info("No users would have been deleted")
    else
      shell_info("No users were deleted")
    end
  end
end
