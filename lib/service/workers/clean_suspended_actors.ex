defmodule Mobilizon.Service.Workers.CleanSuspendedActors do
  @moduledoc """
  Worker to clean unattached media
  """

  use Oban.Worker, queue: "background"
  alias Mobilizon.Actors
  alias Mobilizon.Service.ActorSuspension

  @suspention_days 30

  @impl Oban.Worker
  def perform(%Job{}) do
    [suspension: @suspention_days]
    |> Actors.list_suspended_actors_to_purge()
    |> Enum.each(&ActorSuspension.suspend_actor(&1, reserve_username: true, suspension: true))
  end
end
