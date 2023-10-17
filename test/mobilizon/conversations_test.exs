defmodule Mobilizon.DiscussionsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Conversations
  alias Mobilizon.Conversations.{Conversation, ConversationParticipant}

  describe "create_conversation/1" do
    @conversation_attrs %{
      text: "A conversation comment",
      published_at: NaiveDateTime.utc_now()
    }

    test "creates a conversation" do
      actor = insert(:actor)
      actor_participant1 = insert(:actor)
      actor_participant2 = insert(:actor)
      participants = [actor, actor_participant1, actor_participant2]

      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(
                 Map.merge(@conversation_attrs, %{
                   actor_id: actor.id,
                   participants: participants
                 })
               )

      participants =
        Conversations.list_conversation_participants_for_conversation(conversation.id)

      assert length(participants) == 3

      assert %ConversationParticipant{unread: false} =
               Enum.find(participants, &(&1.actor_id == actor.id))

      assert %ConversationParticipant{unread: true} =
               Enum.find(participants, &(&1.actor_id == actor_participant1.id))

      assert %ConversationParticipant{unread: true} =
               Enum.find(participants, &(&1.actor_id == actor_participant2.id))
    end
  end

  describe "reply_to_conversation/2" do
    @conversation_attrs %{
      text: "A conversation reply",
      published_at: NaiveDateTime.utc_now()
    }

    test "creates a reply" do
      conversation = insert(:conversation)
      actor = insert(:actor)
      actor_participant1 = insert(:actor)
      actor_participant2 = insert(:actor)
      insert(:conversation_participant, conversation: conversation, actor: actor)
      insert(:conversation_participant, conversation: conversation, actor: actor_participant1)
      insert(:conversation_participant, conversation: conversation, actor: actor_participant2)

      participants = [actor, actor_participant1, actor_participant2]

      assert {:ok, %Conversation{} = conversation} =
               Conversations.reply_to_conversation(
                 conversation,
                 Map.merge(@conversation_attrs, %{
                   actor_id: actor.id,
                   participants: participants
                 })
               )

      participants =
        Conversations.list_conversation_participants_for_conversation(conversation.id)

      assert length(participants) == 3

      assert %ConversationParticipant{unread: false} =
               Enum.find(participants, &(&1.actor_id == actor.id))

      assert %ConversationParticipant{unread: true} =
               Enum.find(participants, &(&1.actor_id == actor_participant1.id))

      assert %ConversationParticipant{unread: true} =
               Enum.find(participants, &(&1.actor_id == actor_participant2.id))
    end
  end
end
