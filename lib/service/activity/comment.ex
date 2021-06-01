defmodule Mobilizon.Service.Activity.Comment do
  @moduledoc """
  Insert a comment activity
  """
  alias Mobilizon.{Discussions, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.{ActivityBuilder, LegacyNotifierBuilder}

  @behaviour Activity

  @impl Activity
  def insert_activity(comment, options \\ [])

  def insert_activity(
        %Comment{
          actor_id: actor_id,
          event_id: event_id
        } = comment,
        options
      )
      when not is_nil(actor_id) and not is_nil(event_id) do
    with {:ok, %Event{} = event} <-
           Events.get_event_with_preload(event_id) do
      # Notify the actors mentionned
      notify_mentionned(comment, event)

      # Notify participants if there's a new announcement
      notify_announcement(comment, event)

      # Notify event organizer or group that there's new comments
      notify_organizer(comment, event, options)
    end
  end

  def insert_activity(_, _), do: {:ok, nil}

  @impl Activity
  def get_object(comment_id) do
    Discussions.get_comment(comment_id)
  end

  defp notify_mentionned(%Comment{actor_id: actor_id, id: comment_id, mentions: mentions}, %Event{
         uuid: uuid,
         title: title
       })
       when length(mentions) > 0 do
    LegacyNotifierBuilder.enqueue(:legacy_notify, %{
      "type" => :comment,
      "subject" => :event_comment_mention,
      "subject_params" => %{
        event_uuid: uuid,
        event_title: title
      },
      "author_id" => actor_id,
      "object_type" => :comment,
      "object_id" => to_string(comment_id),
      "inserted_at" => DateTime.utc_now(),
      "mentions" => Enum.map(mentions, & &1.actor_id)
    })
  end

  defp notify_mentionned(_, _), do: {:ok, :skipped}

  defp notify_announcement(
         %Comment{actor_id: actor_id, is_announcement: true, id: comment_id},
         %Event{
           id: event_id,
           uuid: uuid,
           title: title
         }
       ) do
    LegacyNotifierBuilder.enqueue(:legacy_notify, %{
      "type" => :comment,
      "subject" => :participation_event_comment,
      "subject_params" => %{
        event_id: event_id,
        event_uuid: uuid,
        event_title: title
      },
      "author_id" => actor_id,
      "object_type" => :comment,
      "object_id" => to_string(comment_id),
      "inserted_at" => DateTime.utc_now()
    })
  end

  defp notify_announcement(_, _), do: {:ok, :skipped}

  @spec notify_organizer(Comment.t(), Event.t(), Keyword.t()) ::
          {:ok, Oban.Job.t()} | {:ok, :skipped}
  defp notify_organizer(
         %Comment{
           actor_id: actor_id,
           is_announcement: true,
           in_reply_to_comment_id: in_reply_to_comment_id,
           id: comment_id
         },
         %Event{
           uuid: uuid,
           title: title,
           attributed_to: %Actor{type: :Group, id: group_id}
         },
         options
       ) do
    ActivityBuilder.enqueue(:build_activity, %{
      "type" => "event",
      "subject" => Keyword.fetch!(options, :subject),
      "subject_params" => %{
        event_title: title,
        event_uuid: uuid,
        comment_reply_to: !is_nil(in_reply_to_comment_id)
      },
      "group_id" => group_id,
      "author_id" => actor_id,
      "object_type" => "comment",
      "object_id" => to_string(comment_id),
      "inserted_at" => DateTime.utc_now()
    })
  end

  defp notify_organizer(
         %Comment{
           actor_id: actor_id,
           is_announcement: true,
           in_reply_to_comment_id: in_reply_to_comment_id,
           id: comment_id
         },
         %Event{
           uuid: uuid,
           title: title,
           attributed_to: nil,
           organizer_actor_id: organizer_actor_id
         },
         _options
       )
       when actor_id !== organizer_actor_id do
    LegacyNotifierBuilder.enqueue(:legacy_notify, %{
      "type" => :comment,
      "subject" => :event_new_comment,
      "subject_params" => %{
        event_title: title,
        event_uuid: uuid,
        comment_reply_to: !is_nil(in_reply_to_comment_id)
      },
      "author_id" => actor_id,
      "object_type" => :comment,
      "object_id" => to_string(comment_id),
      "inserted_at" => DateTime.utc_now()
    })
  end

  defp notify_organizer(_, _, _), do: {:ok, :skipped}
end
