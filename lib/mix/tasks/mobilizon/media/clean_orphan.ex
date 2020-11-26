defmodule Mix.Tasks.Mobilizon.Media.CleanOrphan do
  @moduledoc """
  Task to accept an instance follow request
  """
  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.Service.CleanOrphanMedia

  @shortdoc "Clean orphan media"

  @grace_period Mobilizon.Config.get([:instance, :orphan_upload_grace_period_hours], 48)

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

    case CleanOrphanMedia.clean(dry_run: dry_run, grace_period: grace_period) do
      {:ok, medias} ->
        if length(medias) > 0 do
          if dry_run or verbose do
            details(medias, dry_run, verbose)
          end

          result(dry_run, length(medias))
        else
          empty_result(dry_run)
        end

        :ok

      _err ->
        shell_error("Error while cleaning orphan media files")
    end
  end

  @spec details(list(Media.t()), boolean(), boolean()) :: :ok
  defp details(medias, dry_run, verbose) do
    cond do
      dry_run ->
        shell_info("List of files that would have been deleted")

      verbose ->
        shell_info("List of files that have been deleted")
    end

    Enum.each(medias, fn media ->
      shell_info("ID: #{media.id}, Actor: #{media.actor_id}, URL: #{media.file.url}")
    end)
  end

  @spec result(boolean(), boolean()) :: :ok
  defp result(dry_run, nb_medias) do
    if dry_run do
      shell_info("#{nb_medias} files would have been deleted")
    else
      shell_info("#{nb_medias} files have been deleted")
    end
  end

  @spec empty_result(boolean()) :: :ok
  defp empty_result(dry_run) do
    if dry_run do
      shell_info("No files would have been deleted")
    else
      shell_info("No files were deleted")
    end
  end
end
