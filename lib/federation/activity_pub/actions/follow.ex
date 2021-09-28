defmodule Mobilizon.Federation.ActivityPub.Actions.Follow do
  @moduledoc """
  Follow people
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Federation.ActivityPub.Types
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Web.Endpoint
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1,
      make_unfollow_data: 4
    ]

  @doc """
  Make an actor follow another, using an activity of type `Follow`
  """
  @spec follow(Actor.t(), Actor.t(), String.t() | nil, boolean, map) ::
          {:ok, Activity.t(), Follower.t()} | {:error, atom | Ecto.Changeset.t() | String.t()}
  def follow(
        %Actor{} = follower,
        %Actor{} = followed,
        activity_id \\ nil,
        local \\ true,
        additional \\ %{}
      ) do
    if followed.id != follower.id do
      case Types.Actors.follow(
             follower,
             followed,
             local,
             Map.merge(additional, %{"activity_id" => activity_id})
           ) do
        {:ok, activity_data, %Follower{} = follower} ->
          {:ok, activity} = create_activity(activity_data, local)
          maybe_federate(activity)
          {:ok, activity, follower}

        {:error, err} ->
          {:error, err}
      end
    else
      {:error, "Can't follow yourself"}
    end
  end

  @doc """
  Make an actor unfollow another, using an activity of type `Undo` a `Follow`.
  """
  @spec unfollow(Actor.t(), Actor.t(), String.t() | nil, boolean()) ::
          {:ok, Activity.t(), Follower.t()} | {:error, String.t()}
  def unfollow(%Actor{} = follower, %Actor{} = followed, activity_id \\ nil, local \\ true) do
    with {:ok, %Follower{id: follow_id} = follow} <- Actors.unfollow(followed, follower) do
      # We recreate the follow activity
      follow_as_data =
        Convertible.model_to_as(%{follow | actor: follower, target_actor: followed})

      {:ok, follow_activity} = create_activity(follow_as_data, local)
      activity_unfollow_id = activity_id || "#{Endpoint.url()}/unfollow/#{follow_id}/activity"

      unfollow_data =
        make_unfollow_data(follower, followed, follow_activity, activity_unfollow_id)

      {:ok, activity} = create_activity(unfollow_data, local)
      maybe_federate(activity)
      {:ok, activity, follow}
    end
  end
end
