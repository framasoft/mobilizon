defmodule Mobilizon.Federation.ActivityPub.Actions.Delete do
  @moduledoc """
  Delete things
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Activity
  alias Mobilizon.Federation.ActivityPub.Types.{Entity, Managable, Ownable}
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1,
      maybe_relay_if_group_activity: 2,
      check_for_actor_key_rotation: 1
    ]

  @doc """
  Delete an entity, using an activity of type `Delete`
  """
  @spec delete(Entity.t(), Actor.t(), boolean, map) :: {:ok, Activity.t(), Entity.t()}
  def delete(object, actor, local \\ true, additional \\ %{}) do
    with {:ok, activity_data, actor, object} <-
           Managable.delete(object, actor, local, additional),
         group <- Ownable.group_actor(object),
         :ok <- check_for_actor_key_rotation(actor),
         {:ok, activity} <- create_activity(activity_data, local),
         :ok <- maybe_federate(activity),
         :ok <- maybe_relay_if_group_activity(activity, group) do
      {:ok, activity, object}
    end
  end
end
