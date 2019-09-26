defmodule MobilizonWeb.API.Participations do
  @moduledoc """
  Common API to join events and groups.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Service.ActivityPub

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

  def accept(
        %Participant{} = participation,
        %Actor{} = moderator
      ) do
    with {:ok, activity, _} <-
           ActivityPub.accept(
             %{
               to: [participation.actor.url],
               actor: moderator.url,
               object: participation.url
             },
             "#{MobilizonWeb.Endpoint.url()}/accept/join/#{participation.id}"
           ),
         {:ok, %Participant{role: :participant} = participation} <-
           Events.update_participant(participation, %{"role" => :participant}) do
      {:ok, activity, participation}
    end
  end

  def reject(
        %Participant{} = participation,
        %Actor{} = moderator
      ) do
    with {:ok, activity, _} <-
           ActivityPub.reject(
             %{
               to: [participation.actor.url],
               actor: moderator.url,
               object: participation.url
             },
             "#{MobilizonWeb.Endpoint.url()}/reject/join/#{participation.id}"
           ),
         {:ok, %Participant{} = participation} <-
           Events.delete_participant(participation) do
      {:ok, activity, participation}
    end
  end
end
