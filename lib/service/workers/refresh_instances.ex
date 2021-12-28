defmodule Mobilizon.Service.Workers.RefreshInstances do
  @moduledoc """
  Worker to refresh the instances materialized view and the relay actors
  """

  use Oban.Worker, unique: [period: :infinity, keys: [:event_uuid, :action]]

  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Instances
  alias Mobilizon.Instances.Instance
  alias Oban.Job

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Job{}) do
    Instances.refresh()

    Instances.all_domains()
    |> Enum.each(&refresh_instance_actor/1)
  end

  @spec refresh_instance_actor(Instance.t()) ::
          {:ok, Mobilizon.Actors.Actor.t()}
          | {:error,
             Mobilizon.Federation.ActivityPub.Actor.make_actor_errors()
             | Mobilizon.Federation.WebFinger.finger_errors()}

  defp refresh_instance_actor(%Instance{domain: domain}) do
    ActivityPubActor.find_or_make_actor_from_nickname("relay@#{domain}")
  end
end
