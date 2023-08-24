defmodule Mobilizon.Service.Activity.Participant do
  @moduledoc """
  Insert an event activity
  """
  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Participant
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.ActivityBuilder

  @behaviour Activity

  @impl Activity
  def insert_activity(event, options \\ [])

  def insert_activity(
        %Participant{event_id: event_id, actor_id: actor_id, id: participant_id} =
          _participant,
        options
      ) do
    actor = Actors.get_actor(actor_id)
    event = Events.get_event!(event_id)
    subject = Keyword.fetch!(options, :subject)

    ActivityBuilder.enqueue(:build_activity, %{
      "type" => "event",
      "subject" => subject,
      "subject_params" => %{
        actor_name: Actor.display_name(actor),
        event_title: event.title,
        event_uuid: event.uuid
      },
      "group_id" => event.attributed_to_id,
      "author_id" => actor.id,
      "object_type" => "participant",
      "object_id" => participant_id,
      "inserted_at" => DateTime.utc_now()
    })
  end

  @impl Activity
  def insert_activity(_, _), do: {:ok, nil}

  @impl Activity
  def get_object(participant_id) do
    Events.get_participant(participant_id)
  end
end
