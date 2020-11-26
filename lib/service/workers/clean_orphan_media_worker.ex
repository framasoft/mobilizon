defmodule Mobilizon.Service.Workers.CleanOrphanMediaWorker do
  @moduledoc """
  Worker to clean orphan media
  """

  use Oban.Worker, queue: "background"
  alias Mobilizon.Service.CleanOrphanMedia

  @grace_period Mobilizon.Config.get([:instance, :orphan_upload_grace_period_hours], 48)

  @impl Oban.Worker
  def perform(%Job{}) do
    if Mobilizon.Config.get!([:instance, :remove_orphan_uploads]) and should_perform?() do
      CleanOrphanMedia.clean()
    end
  end

  @spec should_perform? :: boolean()
  defp should_perform? do
    case Cachex.get(:key_value, "last_media_cleanup") do
      {:ok, %DateTime{} = last_media_cleanup} ->
        DateTime.compare(
          last_media_cleanup,
          DateTime.add(DateTime.utc_now(), @grace_period * -3600)
        ) == :lt

      _ ->
        true
    end
  end
end
