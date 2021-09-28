defmodule Mobilizon.Federation.ActivityPub.Actions.Join do
  @moduledoc """
  Join things
  """

  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Federation.ActivityPub.Types
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [
      create_activity: 2,
      maybe_federate: 1
    ]

  @doc """
  Join an entity (an event or a group), using an activity of type `Join`
  """
  @spec join(Event.t(), Actor.t(), boolean, map) ::
          {:ok, Activity.t(), Participant.t()} | {:error, :maximum_attendee_capacity}
  @spec join(Actor.t(), Actor.t(), boolean, map) :: {:ok, Activity.t(), Member.t()}
  def join(entity_to_join, actor_joining, local \\ true, additional \\ %{})

  def join(%Event{} = event, %Actor{} = actor, local, additional) do
    case Types.Events.join(event, actor, local, additional) do
      {:ok, activity_data, participant} ->
        {:ok, activity} = create_activity(activity_data, local)
        maybe_federate(activity)
        {:ok, activity, participant}

      {:error, :maximum_attendee_capacity_reached} ->
        {:error, :maximum_attendee_capacity_reached}

      {:accept, accept} ->
        accept
    end
  end

  def join(%Actor{type: :Group} = group, %Actor{} = actor, local, additional) do
    with {:ok, activity_data, %Member{} = member} <-
           Types.Actors.join(group, actor, local, additional),
         {:ok, activity} <- create_activity(activity_data, local),
         :ok <- maybe_federate(activity) do
      {:ok, activity, member}
    else
      {:accept, accept} ->
        accept
    end
  end
end
