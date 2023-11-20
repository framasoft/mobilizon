defmodule Mobilizon.Service.Activity.ConversationTest do
  @moduledoc """
  Test the Comment activity provider module
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations
  alias Mobilizon.Conversations.{Conversation, ConversationParticipant}
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Service.Activity.Conversation, as: ConversationActivity
  alias Mobilizon.Service.Workers.LegacyNotifierBuilder
  alias Mobilizon.Users.User

  use Mobilizon.DataCase
  use Oban.Testing, repo: Mobilizon.Storage.Repo
  import Mobilizon.Factory

  describe "handle conversation" do
    test "with participants" do
      %User{} = user = insert(:user)
      %Actor{id: actor_id} = actor = insert(:actor, user: user)

      %Conversation{
        id: conversation_id,
        last_comment: %Comment{actor_id: last_comment_actor_id}
      } =
        conversation = insert(:conversation, event: nil)

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
          "author_id" => last_comment_actor_id,
          "participant" => %{"actor_id" => actor_id, "id" => conversation_participant_actor_id},
          "object_id" => to_string(conversation_id),
          "object_type" => "conversation",
          "op" => "legacy_notify",
          "subject" => "conversation_created",
          "subject_params" => %{
            "conversation_id" => conversation_id,
            "conversation_participant_id" => conversation_participant_actor_id
          },
          "type" => "conversation"
        }
      )

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => last_comment_actor_id,
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
            "conversation_participant_id" => conversation_participant_id
          },
          "type" => "conversation"
        }
      )
    end
  end
end
