defmodule Mobilizon.Service.Workers.CleanApplicationData do
  @moduledoc """
  Worker to send activity recaps
  """

  use Oban.Worker, queue: "background"
  alias Mobilizon.Service.Auth.Applications
  require Logger

  @impl Oban.Worker
  def perform(%Job{args: %{type: :application}}) do
    Logger.info("Cleaning expired applications data")

    # TODO: Clear unused applications after a while
  end

  @impl Oban.Worker
  def perform(%Job{args: %{type: :application_token}}) do
    Logger.info("Cleaning expired application tokens data")

    Applications.prune_old_tokens()
    :ok
  end

  @impl Oban.Worker
  def perform(%Job{args: %{type: :application_device_activation}}) do
    Logger.info("Cleaning expired application device activation data")

    Applications.prune_old_application_device_activations()
    :ok
  end
end
