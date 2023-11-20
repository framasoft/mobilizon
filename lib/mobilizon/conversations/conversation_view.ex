defmodule Mobilizon.Conversations.ConversationView do
  @moduledoc """
  Represents a conversation view for GraphQL API
  """

  defstruct [
    :id,
    :conversation_participant_id,
    :origin_comment,
    :origin_comment_id,
    :last_comment,
    :last_comment_id,
    :event,
    :event_id,
    :actor,
    :actor_id,
    :unread,
    :inserted_at,
    :updated_at,
    :participants
  ]
end
