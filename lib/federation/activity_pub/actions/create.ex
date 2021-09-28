defmodule Mobilizon.Federation.ActivityPub.Actions.Create do
  @moduledoc """
  Create things
  """
  alias Mobilizon.Tombstone
  alias Mobilizon.Federation.ActivityPub.{Activity, Types}
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1,
      maybe_relay_if_group_activity: 1
    ]

  @type create_entities ::
          :event | :comment | :discussion | :actor | :todo_list | :todo | :resource | :post

  @doc """
  Create an activity of type `Create`

    * Creates the object, which returns AS data
    * Wraps ActivityStreams data into a `Create` activity
    * Creates an `Mobilizon.Federation.ActivityPub.Activity` from this
    * Federates (asynchronously) the activity
    * Returns the activity
  """
  @spec create(create_entities(), map(), boolean, map()) ::
          {:ok, Activity.t(), Entity.t()}
          | {:error, :entity_tombstoned | atom() | Ecto.Changeset.t()}
  def create(type, args, local \\ false, additional \\ %{}) do
    Logger.debug("creating an activity")
    Logger.debug(inspect(args))

    case check_for_tombstones(args) do
      nil ->
        case do_create(type, args, additional) do
          {:ok, entity, create_data} ->
            {:ok, activity} = create_activity(create_data, local)
            maybe_federate(activity)
            maybe_relay_if_group_activity(activity)
            {:ok, activity, entity}

          {:error, err} ->
            {:error, err}
        end

      %Tombstone{} ->
        {:error, :entity_tombstoned}
    end
  end

  @spec do_create(create_entities(), map(), map()) ::
          {:ok, Entity.t(), Activity.t()} | {:error, Ecto.Changeset.t() | atom()}
  defp do_create(type, args, additional) do
    case type do
      :event -> Types.Events.create(args, additional)
      :comment -> Types.Comments.create(args, additional)
      :discussion -> Types.Discussions.create(args, additional)
      :actor -> Types.Actors.create(args, additional)
      :todo_list -> Types.TodoLists.create(args, additional)
      :todo -> Types.Todos.create(args, additional)
      :resource -> Types.Resources.create(args, additional)
      :post -> Types.Posts.create(args, additional)
    end
  end

  @spec check_for_tombstones(map()) :: Tombstone.t() | nil
  defp check_for_tombstones(%{url: url}), do: Tombstone.find_tombstone(url)
  defp check_for_tombstones(_), do: nil
end
