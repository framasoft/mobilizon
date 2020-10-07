defmodule Mobilizon.GraphQL.API.Participations do
  @moduledoc """
  Common API to join events and groups.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Activity
  alias Mobilizon.Service.Notifications.Scheduler
  alias Mobilizon.Web.Email.Participation

  @spec join(Event.t(), Actor.t(), map()) :: {:ok, Activity.t(), Participant.t()}
  def join(%Event{id: event_id} = event, %Actor{id: actor_id} = actor, args \\ %{}) do
    with {:error, :participant_not_found} <-
           Mobilizon.Events.get_participant(event_id, actor_id, args),
         {:ok, activity, participant} <-
           ActivityPub.join(event, actor, Map.get(args, :local, true), %{metadata: args}) do
      {:ok, activity, participant}
    end
  end

  @spec leave(Event.t(), Actor.t()) :: {:ok, Activity.t(), Participant.t()}
  def leave(%Event{} = event, %Actor{} = actor, args \\ %{}) do
    with {:ok, activity, participant} <-
           ActivityPub.leave(event, actor, Map.get(args, :local, true), %{metadata: args}) do
      {:ok, activity, participant}
    end
  end

  @doc """
  Update participation status
  """
  @spec update(Participant.t(), Actor.t(), atom()) :: {:ok, Activity.t(), Participant.t()}
  def update(%Participant{} = participation, %Actor{} = moderator, :participant),
    do: accept(participation, moderator)

  @spec update(Participant.t(), Actor.t(), atom()) :: {:ok, Activity.t(), Participant.t()}
  def update(%Participant{} = participation, %Actor{} = _moderator, :not_approved) do
    with {:ok, %Participant{} = participant} <-
           Events.update_participant(participation, %{role: :not_approved}) do
      Scheduler.pending_participation_notification(participation.event)
      {:ok, nil, participant}
    end
  end

  @spec update(Participant.t(), Actor.t(), atom()) :: {:ok, Activity.t(), Participant.t()}
  def update(%Participant{} = participation, %Actor{} = moderator, :rejected),
    do: reject(participation, moderator)

  @spec accept(Participant.t(), Actor.t()) :: {:ok, Activity.t(), Participant.t()}
  defp accept(
         %Participant{} = participation,
         %Actor{} = moderator
       ) do
    with {:ok, activity, %Participant{role: :participant} = participation} <-
           ActivityPub.accept(
             :join,
             participation,
             true,
             %{"actor" => moderator.url}
           ),
         :ok <- Participation.send_emails_to_local_user(participation) do
      {:ok, activity, participation}
    end
  end

  @spec reject(Participant.t(), Actor.t()) :: {:ok, Activity.t(), Participant.t()}
  defp reject(
         %Participant{} = participation,
         %Actor{} = moderator
       ) do
    with {:ok, activity, %Participant{role: :rejected} = participation} <-
           ActivityPub.reject(
             :join,
             participation,
             %{"actor" => moderator.url}
           ),
         :ok <- Participation.send_emails_to_local_user(participation) do
      {:ok, activity, participation}
    end
  end
end
