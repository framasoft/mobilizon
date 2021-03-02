defmodule Mobilizon.Service.Workers.CleanOldActivityWorker do
  @moduledoc """
  Worker to clean old activity
  """

  use Oban.Worker, queue: "background"
  alias Mobilizon.Service.CleanOldActivity

  @impl Oban.Worker
  def perform(%Job{}) do
    CleanOldActivity.clean()
  end
end
