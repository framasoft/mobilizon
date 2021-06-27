defmodule Mobilizon.Service.Activity.Comment do
  @moduledoc """
  Insert a comment activity
  """
  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Discussions, Events}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.{ActivityBuilder, LegacyNotifierBuilder}

  import Mobilizon.Service.Activity.Utils, only: [maybe_inserted_at: 0]

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
      res =
        []
        # Notify the actors mentionned
        |> handle_notification(:mentionned, comment, event, options)
        # Notify participants if there's a new announcement
        |> handle_notification(:announcement, comment, event, options)
        # Notify event organizer or group that there's new comments
        |> handle_notification(:organizer, comment, event, options)

      {:ok, res}
    end
  end

  def insert_activity(_, _), do: {:ok, nil}

  @impl Activity
  def get_object(comment_id) do
    Discussions.get_comment(comment_id)
  end

  @common_params %{
    "type" => :comment,
    "object_type" => :comment
  }

  defp handle_notification(global_res, function, comment, event, options) do
    case notify(function, comment, event, options) do
      {:ok, res} -> Keyword.put(global_res, function, res)
      _ -> Keyword.put(global_res, function, :error)
    end
  end

  @spec legacy_notifier_enqueue(map()) :: :ok
  defp legacy_notifier_enqueue(args) do
    LegacyNotifierBuilder.enqueue(
      :legacy_notify,
      @common_params |> Map.merge(maybe_inserted_at()) |> Map.merge(args)
    )
  end

  @type notification_type :: atom()

  # An actor is mentionned
  @spec notify(notification_type(), Comment.t(), Event.t(), Keyword.t()) ::
          {:ok, Oban.Job.t()} | {:ok, :skipped}
  defp notify(
         :mentionned,
         %Comment{actor_id: actor_id, id: comment_id, mentions: mentions},
         %Event{
           uuid: uuid,
           title: title
         },
         _options
       )
       when length(mentions) > 0 do
    legacy_notifier_enqueue(%{
      "subject" => :event_comment_mention,
      "subject_params" => %{
        event_uuid: uuid,
        event_title: title
      },
      "author_id" => actor_id,
      "object_id" => to_string(comment_id),
      "mentions" => Enum.map(mentions, & &1.actor_id)
    })

    {:ok, :enqueued}
  end

  # An event has a new announcement, send it to the participants
  defp notify(
         :announcement,
         %Comment{actor_id: actor_id, is_announcement: true, id: comment_id},
         %Event{
           id: event_id,
           uuid: uuid,
           title: title
         },
         _options
       ) do
    legacy_notifier_enqueue(%{
      "subject" => :participation_event_comment,
      "subject_params" => %{
        event_id: event_id,
        event_uuid: uuid,
        event_title: title
      },
      "author_id" => actor_id,
      "object_id" => to_string(comment_id)
    })

    {:ok, :enqueued}
  end

  # A group event has a new comment, send it as an activity
  defp notify(
         :announcement,
         %Comment{
           actor_id: actor_id,
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

    {:ok, :enqueued}
  end

  # An event has a new comment, send it to the organizer
  defp notify(
         :organizer,
         %Comment{
           actor_id: actor_id,
           in_reply_to_comment_id: in_reply_to_comment_id,
           id: comment_id,
           uuid: comment_uuid
         } = comment,
         %Event{
           uuid: event_uuid,
           title: title,
           attributed_to: nil,
           organizer_actor_id: organizer_actor_id
         },
         _options
       )
       when actor_id !== organizer_actor_id do
    legacy_notifier_enqueue(%{
      "subject" => :event_new_comment,
      "subject_params" => %{
        event_title: title,
        event_uuid: event_uuid,
        comment_reply_to: !is_nil(in_reply_to_comment_id),
        comment_uuid: comment_uuid,
        comment_reply_to_uuid: reply_to_comment_uuid(comment)
      },
      "author_id" => actor_id,
      "object_id" => to_string(comment_id)
    })

    {:ok, :enqueued}
  end

  defp notify(_, _, _, _), do: {:ok, :skipped}

  @spec reply_to_comment_uuid(Comment.t()) :: String.t() | nil
  defp reply_to_comment_uuid(%Comment{in_reply_to_comment: %Comment{uuid: comment_reply_to_uuid}}),
    do: comment_reply_to_uuid

  defp reply_to_comment_uuid(%Comment{in_reply_to_comment: _}), do: nil
end
