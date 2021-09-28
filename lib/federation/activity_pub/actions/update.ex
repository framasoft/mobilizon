defmodule Mobilizon.Federation.ActivityPub.Actions.Update do
  @moduledoc """
  Update things
  """
  alias Mobilizon.Federation.ActivityPub.Activity
  alias Mobilizon.Federation.ActivityPub.Types.Managable
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1,
      maybe_relay_if_group_activity: 1
    ]

  @doc """
  Create an activity of type `Update`

    * Updates the object, which returns AS data
    * Wraps ActivityStreams data into a `Update` activity
    * Creates an `Mobilizon.Federation.ActivityPub.Activity` from this
    * Federates (asynchronously) the activity
    * Returns the activity
  """
  @spec update(Entity.t(), map(), boolean, map()) ::
          {:ok, Activity.t(), Entity.t()} | {:error, atom() | Ecto.Changeset.t()}
  def update(old_entity, args, local \\ false, additional \\ %{}) do
    Logger.debug("updating an activity")
    Logger.debug(inspect(args))

    case Managable.update(old_entity, args, additional) do
      {:ok, entity, update_data} ->
        {:ok, activity} = create_activity(update_data, local)
        maybe_federate(activity)
        maybe_relay_if_group_activity(activity)
        {:ok, activity, entity}

      {:error, err} ->
        Logger.error("Something went wrong while creating an activity")
        Logger.debug(inspect(err))
        {:error, err}
    end
  end
end
