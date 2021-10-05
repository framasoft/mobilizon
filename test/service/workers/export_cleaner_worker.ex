defmodule Mobilizon.Service.Workers.ExportCleanerWorkerTest do
  @moduledoc """
  Test the export cleaner worker
  """

  alias Mobilizon.Service.Workers.ExportCleanerWorker
  alias Oban.Job

  use Mobilizon.DataCase

  test "Run clean" do
    assert :ok == ExportCleanerWorker.perform(%Job{})
  end
end
