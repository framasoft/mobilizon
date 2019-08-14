defmodule MobilizonWeb.API.Participations do
  @moduledoc """
  Common API to join events and groups
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.ActivityPub
  require Logger

  @spec join(Event.t(), Actor.t()) :: {:ok, Participant.t()}
  def join(%Event{id: event_id} = event, %Actor{id: actor_id} = actor) do
    with {:error, :participant_not_found} <- Mobilizon.Events.get_participant(event_id, actor_id),
         {:ok, activity, participant} <- ActivityPub.join(event, actor, true) do
      {:ok, activity, participant}
    end
  end

  def leave(%Event{} = event, %Actor{} = actor) do
    with {:ok, activity, participant} <- ActivityPub.leave(event, actor, true) do
      {:ok, activity, participant}
    end
  end
end
