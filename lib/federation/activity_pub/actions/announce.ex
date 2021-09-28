defmodule Mobilizon.Federation.ActivityPub.Actions.Announce do
  @moduledoc """
  Announce things
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Activity
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Share

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1,
      make_announce_data: 3,
      make_announce_data: 4,
      make_unannounce_data: 3
    ]

  @doc """
  Announce (reshare) an activity to the world, using an activity of type `Announce`.
  """
  @spec announce(Actor.t(), ActivityStream.t(), String.t() | nil, boolean, boolean) ::
          {:ok, Activity.t(), ActivityStream.t()} | {:error, any()}
  def announce(
        %Actor{} = actor,
        object,
        activity_id \\ nil,
        local \\ true,
        public \\ true
      ) do
    with {:ok, %Actor{id: object_owner_actor_id}} <-
           ActivityPubActor.get_or_fetch_actor_by_url(object["actor"]),
         {:ok, %Share{} = _share} <- Share.create(object["id"], actor.id, object_owner_actor_id) do
      announce_data = make_announce_data(actor, object, activity_id, public)
      {:ok, activity} = create_activity(announce_data, local)
      :ok = maybe_federate(activity)
      {:ok, activity, object}
    end
  end

  @doc """
  Cancel the announcement of an activity to the world, using an activity of type `Undo` an `Announce`.
  """
  @spec unannounce(Actor.t(), ActivityStream.t(), String.t() | nil, String.t() | nil, boolean) ::
          {:ok, Activity.t(), ActivityStream.t()}
  def unannounce(
        %Actor{} = actor,
        object,
        activity_id \\ nil,
        cancelled_activity_id \\ nil,
        local \\ true
      ) do
    announce_activity = make_announce_data(actor, object, cancelled_activity_id)
    unannounce_data = make_unannounce_data(actor, announce_activity, activity_id)
    {:ok, unannounce_activity} = create_activity(unannounce_data, local)
    maybe_federate(unannounce_activity)
    {:ok, unannounce_activity, object}
  end
end
