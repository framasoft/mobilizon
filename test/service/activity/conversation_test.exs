defmodule Mobilizon.Service.Activity.ConversationTest do
  @moduledoc """
  Test the Comment activity provider module
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations
  alias Mobilizon.Conversations.{Conversation, ConversationParticipant}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Activity.Conversation, as: ConversationActivity
  alias Mobilizon.Service.Workers.LegacyNotifierBuilder
  alias Mobilizon.Users.User

  use Mobilizon.DataCase
  use Oban.Testing, repo: Mobilizon.Storage.Repo
  import Mobilizon.Factory

  describe "handle activity from event private announcement conversation" do
    test "when conversation initial comment author is not an organizer" do
      %User{} = user = insert(:user)
      %Actor{id: actor_id} = actor = insert(:actor, user: user)

      %Actor{} = organizer_actor = insert(:actor)

      %Event{} = event = insert(:event)

      %Comment{} = comment = insert(:comment, actor: organizer_actor)

      %Conversation{id: conversation_id} =
        conversation =
        insert(:conversation, event: event, last_comment: comment, origin_comment: comment)

      %ConversationParticipant{id: conversation_participant_actor_id} =
        insert(:conversation_participant, actor: actor, conversation: conversation)

      %ConversationParticipant{
        id: conversation_participant_id,
        actor: %Actor{id: conversation_other_participant_actor_id}
      } = insert(:conversation_participant, conversation: conversation)

      conversation = Conversations.get_conversation(conversation_id)

      assert {:ok, _} =
               ConversationActivity.insert_activity(conversation, subject: "conversation_created")

      refute_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => organizer_actor.id,
          "participant" => %{"actor_id" => actor_id, "id" => conversation_participant_actor_id},
          "object_id" => to_string(conversation_id),
          "object_type" => "conversation",
          "op" => "legacy_notify",
          "subject" => "conversation_created",
          "subject_params" => %{
            "conversation_id" => conversation_id,
            "conversation_participant_id" => conversation_participant_actor_id,
            "conversation_event_id" => event.id,
            "conversation_event_title" => event.title,
            "conversation_event_uuid" => event.uuid
          },
          "type" => "conversation"
        }
      )

      refute_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => organizer_actor.id,
          "participant" => %{
            "actor_id" => conversation_other_participant_actor_id,
            "id" => conversation_participant_id
          },
          "object_id" => to_string(conversation_id),
          "object_type" => "conversation",
          "op" => "legacy_notify",
          "subject" => "conversation_created",
          "subject_params" => %{
            "conversation_id" => conversation_id,
            "conversation_participant_id" => conversation_participant_id,
            "conversation_event_id" => event.id,
            "conversation_event_title" => event.title,
            "conversation_event_uuid" => event.uuid
          },
          "type" => "conversation"
        }
      )

      assert [] = all_enqueued()
    end

    test "an author who is the event organizer" do
      %User{} = user = insert(:user)
      %Actor{id: actor_id} = actor = insert(:actor, user: user)

      %Actor{} = organizer_actor = insert(:actor)

      %Event{} = event = insert(:event, organizer_actor: organizer_actor)

      %Comment{} = comment = insert(:comment, actor: organizer_actor)

      %Conversation{id: conversation_id} =
        conversation =
        insert(:conversation, event: event, last_comment: comment, origin_comment: comment)

      %ConversationParticipant{id: conversation_participant_actor_id} =
        insert(:conversation_participant, actor: actor, conversation: conversation)

      %ConversationParticipant{
        id: conversation_participant_id,
        actor: %Actor{id: conversation_other_participant_actor_id}
      } = insert(:conversation_participant, conversation: conversation)

      conversation = Conversations.get_conversation(conversation_id)

      assert {:ok, _} =
               ConversationActivity.insert_activity(conversation, subject: "conversation_created")

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => organizer_actor.id,
          "participant" => %{"actor_id" => actor_id, "id" => conversation_participant_actor_id},
          "object_id" => to_string(conversation_id),
          "object_type" => "conversation",
          "op" => "legacy_notify",
          "subject" => "conversation_created",
          "subject_params" => %{
            "conversation_id" => conversation_id,
            "conversation_participant_id" => conversation_participant_actor_id,
            "conversation_event_id" => event.id,
            "conversation_event_title" => event.title,
            "conversation_event_uuid" => event.uuid
          },
          "type" => "conversation"
        }
      )

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => organizer_actor.id,
          "participant" => %{
            "actor_id" => conversation_other_participant_actor_id,
            "id" => conversation_participant_id
          },
          "object_id" => to_string(conversation_id),
          "object_type" => "conversation",
          "op" => "legacy_notify",
          "subject" => "conversation_created",
          "subject_params" => %{
            "conversation_id" => conversation_id,
            "conversation_participant_id" => conversation_participant_id,
            "conversation_event_id" => event.id,
            "conversation_event_title" => event.title,
            "conversation_event_uuid" => event.uuid
          },
          "type" => "conversation"
        }
      )
    end

    test "an author who is member of the event organizer group" do
      %User{} = user = insert(:user)
      %Actor{id: actor_id} = actor = insert(:actor, user: user)

      %Actor{} = organizer_group = insert(:group)

      %Event{} = event = insert(:event, attributed_to: organizer_group)

      %Comment{} = comment = insert(:comment, actor: organizer_group)

      %Conversation{id: conversation_id} =
        conversation =
        insert(:conversation, event: event, last_comment: comment, origin_comment: comment)

      %ConversationParticipant{id: conversation_participant_actor_id} =
        insert(:conversation_participant, actor: actor, conversation: conversation)

      %ConversationParticipant{
        id: conversation_participant_id,
        actor: %Actor{id: conversation_other_participant_actor_id}
      } = insert(:conversation_participant, conversation: conversation)

      conversation = Conversations.get_conversation(conversation_id)

      assert {:ok, _} =
               ConversationActivity.insert_activity(conversation, subject: "conversation_created")

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => organizer_group.id,
          "participant" => %{"actor_id" => actor_id, "id" => conversation_participant_actor_id},
          "object_id" => to_string(conversation_id),
          "object_type" => "conversation",
          "op" => "legacy_notify",
          "subject" => "conversation_created",
          "subject_params" => %{
            "conversation_id" => conversation_id,
            "conversation_participant_id" => conversation_participant_actor_id,
            "conversation_event_id" => event.id,
            "conversation_event_title" => event.title,
            "conversation_event_uuid" => event.uuid
          },
          "type" => "conversation"
        }
      )

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => organizer_group.id,
          "participant" => %{
            "actor_id" => conversation_other_participant_actor_id,
            "id" => conversation_participant_id
          },
          "object_id" => to_string(conversation_id),
          "object_type" => "conversation",
          "op" => "legacy_notify",
          "subject" => "conversation_created",
          "subject_params" => %{
            "conversation_id" => conversation_id,
            "conversation_participant_id" => conversation_participant_id,
            "conversation_event_id" => event.id,
            "conversation_event_title" => event.title,
            "conversation_event_uuid" => event.uuid
          },
          "type" => "conversation"
        }
      )
    end
  end
end
