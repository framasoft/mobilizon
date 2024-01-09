defmodule Mobilizon.Service.Activity.Conversation do
  @moduledoc """
  Insert a conversation activity
  """
  alias Mobilizon.{Actors, Conversations}
  alias Mobilizon.Conversations.{Conversation, ConversationParticipant}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.LegacyNotifierBuilder

  @behaviour Activity

  @impl Activity
  def insert_activity(conversation, options \\ [])

  def insert_activity(
        %Conversation{} = conversation,
        options
      ) do
    subject = Keyword.fetch!(options, :subject)

    send_participant_notifications(subject, conversation, conversation.last_comment, options)
  end

  def insert_activity(_, _), do: {:ok, nil}

  @impl Activity
  def get_object(conversation_id) do
    Conversations.get_conversation(conversation_id)
  end

  # An actor is mentionned
  @spec send_participant_notifications(String.t(), Discussion.t(), Comment.t(), Keyword.t()) ::
          {:ok, Oban.Job.t()} | {:ok, :skipped}
  defp send_participant_notifications(
         subject,
         %Conversation{
           id: conversation_id
         } = conversation,
         %Comment{actor_id: actor_id, text: last_comment_text} = comment,
         _options
       )
       when subject in [
              "conversation_created",
              "conversation_replied",
              "conversation_event_announcement"
            ] do
    # We need to send each notification individually as the conversation URL varies for each participant

    conversation_id
    |> Conversations.list_conversation_participants_for_conversation()
    |> Enum.each(fn %ConversationParticipant{
                      id: conversation_participant_id,
                      actor_id: conversation_participant_actor_id
                    } =
                      conversation_participant ->
      if actor_id != conversation_participant_actor_id and
           can_send_event_announcement?(conversation, comment) do
        LegacyNotifierBuilder.enqueue(
          :legacy_notify,
          %{
            "subject" => subject,
            "subject_params" =>
              Map.merge(
                %{
                  conversation_id: conversation_id,
                  conversation_participant_id: conversation_participant_id,
                  conversation_text: last_comment_text
                },
                event_subject_params(conversation)
              ),
            "type" => :conversation,
            "object_type" => :conversation,
            "author_id" => actor_id,
            "object_id" => to_string(conversation_id),
            "participant" => Map.take(conversation_participant, [:id, :actor_id])
          }
        )
      end
    end)

    {:ok, :enqueued}
  end

  defp send_participant_notifications(_, _, _, _), do: {:ok, :skipped}

  defp event_subject_params(%Conversation{
         event: %Event{
           id: conversation_event_id,
           title: conversation_event_title,
           uuid: conversation_event_uuid
         }
       }),
       do: %{
         conversation_event_id: conversation_event_id,
         conversation_event_title: conversation_event_title,
         conversation_event_uuid: conversation_event_uuid
       }

  defp event_subject_params(_), do: %{}

  @spec can_send_event_announcement?(Conversation.t(), Comment.t()) :: boolean()
  defp can_send_event_announcement?(
         %Conversation{
           event: %Event{
             attributed_to_id: attributed_to_id
           }
         },
         %Comment{actor_id: actor_id}
       )
       when not is_nil(attributed_to_id) do
    attributed_to_id == actor_id or Actors.member?(actor_id, attributed_to_id)
  end

  defp can_send_event_announcement?(
         %Conversation{
           event: %Event{
             organizer_actor_id: organizer_actor_id
           }
         },
         %Comment{actor_id: actor_id}
       )
       when not is_nil(organizer_actor_id) do
    organizer_actor_id == actor_id
  end

  defp can_send_event_announcement?(_, _), do: false
end
