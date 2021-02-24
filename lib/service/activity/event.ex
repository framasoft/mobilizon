defmodule Mobilizon.Service.Activity.Event do
  @moduledoc """
  Insert an event activity
  """
  alias Mobilizon.Actors
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.ActivityBuilder

  @behaviour Activity

  @impl Activity
  def insert_activity(event, options \\ [])

  def insert_activity(
        %Event{attributed_to_id: attributed_to_id, organizer_actor_id: organizer_actor_id} =
          event,
        options
      )
      when not is_nil(attributed_to_id) do
    actor = Actors.get_actor(organizer_actor_id)
    group = Actors.get_actor(attributed_to_id)
    subject = Keyword.fetch!(options, :subject)

    ActivityBuilder.enqueue(:build_activity, %{
      "type" => "event",
      "subject" => subject,
      "subject_params" => %{event_uuid: event.uuid, event_title: event.title},
      "group_id" => group.id,
      "author_id" => actor.id,
      "object_type" => "event",
      "object_id" => if(subject != "event_deleted", do: to_string(event.id), else: nil),
      "inserted_at" => DateTime.utc_now()
    })
  end

  @impl Activity
  def insert_activity(_, _), do: {:ok, nil}
end
