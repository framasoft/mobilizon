defmodule Mobilizon.Service.Workers.ExportCleanerWorker do
  @moduledoc """
  Worker to clean exports
  """

  use Oban.Worker, queue: "background"
  import Mobilizon.Service.Export.Participants.Common, only: [export_modules: 0]

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Job{}) do
    Enum.each(export_modules(), & &1.clean_exports())
  end
end
