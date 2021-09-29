defmodule Mobilizon.Federation.ActivityPub.Actions.Move do
  @moduledoc """
  Move things
  """
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Federation.ActivityPub.{Activity, Types}
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1
    ]

  @spec move(:resource, Resource.t(), map, boolean, map) ::
          {:ok, Activity.t(), Resource.t()} | {:error, Ecto.Changeset.t() | atom()}
  def move(type, old_entity, args, local \\ false, additional \\ %{}) do
    Logger.debug("We're moving something")
    Logger.debug(inspect(args))

    with {:ok, entity, update_data} <-
           (case type do
              :resource -> Types.Resources.move(old_entity, args, additional)
            end) do
      {:ok, activity} = create_activity(update_data, local)
      maybe_federate(activity)
      {:ok, activity, entity}
    end
  end
end
