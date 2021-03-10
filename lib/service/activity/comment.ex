defmodule Mobilizon.Service.Activity.Comment do
  @moduledoc """
  Insert a comment activity
  """
  alias Mobilizon.{Actors, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.ActivityBuilder

  @behaviour Activity

  @impl Activity
  def insert_activity(comment, options \\ [])

  def insert_activity(
        %Comment{
          actor_id: actor_id,
          event_id: event_id,
          in_reply_to_comment_id: in_reply_to_comment_id
        } = comment,
        options
      )
      when not is_nil(actor_id) and not is_nil(event_id) do
    with {:ok, %Event{attributed_to: %Actor{type: :Group} = group} = event} <-
           Events.get_event_with_preload(event_id),
         %Actor{id: actor_id} <- Actors.get_actor(actor_id),
         subject <- Keyword.fetch!(options, :subject) do
      ActivityBuilder.enqueue(:build_activity, %{
        "type" => "event",
        "subject" => subject,
        "subject_params" => %{
          event_title: event.title,
          event_uuid: event.uuid,
          comment_reply_to: !is_nil(in_reply_to_comment_id)
        },
        "group_id" => group.id,
        "author_id" => actor_id,
        "object_type" => "comment",
        "object_id" => to_string(comment.id),
        "inserted_at" => DateTime.utc_now()
      })
    else
      # Event not from group
      {:ok, %Event{}} -> {:ok, nil}
    end
  end

  def insert_activity(_, _), do: {:ok, nil}
end
