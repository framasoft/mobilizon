defmodule Mobilizon.Service.Workers.ActivityBuilder do
  @moduledoc """
  Worker to insert activity items in users feeds
  """

  alias Mobilizon.Activities
  alias Mobilizon.Activities.Activity

  use Mobilizon.Service.Workers.Helper, queue: "activity"

  @impl Oban.Worker
  def perform(%Job{args: args}) do
    with {"build_activity", args} <- Map.pop(args, "op") do
      build_activity(args)
    end
  end

  @spec build_activity(map()) :: {:ok, Activity.t()}
  def build_activity(args) do
    Activities.create_activity(args)
  end
end
