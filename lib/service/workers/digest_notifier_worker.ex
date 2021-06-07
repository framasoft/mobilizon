defmodule Mobilizon.Service.Workers.DigestNotifierWorker do
  @moduledoc """
  Worker to send notifications
  """

  use Mobilizon.Service.Workers.Helper, queue: "notifications"

  @impl Oban.Worker
  def perform(%Job{}) do
    # Get last time activities were send
    # List activities to send
    # Send activites
  end
end
