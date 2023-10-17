defmodule Mobilizon.Service.Activity.ConversationTest do
  @moduledoc """
  Test the Comment activity provider module
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations
  alias Mobilizon.Conversations.Conversation
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

      %Conversation{id: conversation_id, last_comment: %Comment{actor_id: last_comment_actor_id}} =
        conversation = insert(:conversation)

      insert(:conversation_participant, actor: actor, conversation: conversation)
      insert(:conversation_participant, conversation: conversation)

      conversation = Conversations.get_conversation(conversation_id)

      assert {:ok, _} =
               ConversationActivity.insert_activity(conversation, subject: "conversation_created")

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => last_comment_actor_id,
          "participants" => [actor_id],
          "object_id" => to_string(conversation_id),
          "object_type" => "conversation",
          "op" => "legacy_notify",
          "subject" => "conversation_created",
          "subject_params" => %{
            "conversation_id" => conversation_id
          },
          "type" => "conversation"
        }
      )

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => author_id,
          "object_id" => to_string(comment_id),
          "object_type" => "comment",
          "op" => "legacy_notify",
          "subject" => "event_new_comment",
          "subject_params" => %{
            "comment_reply_to_uuid" => nil,
            "event_title" => event_title,
            "event_uuid" => event_uuid,
            "comment_reply_to" => false,
            "comment_uuid" => comment_uuid
          },
          "type" => "comment"
        }
      )
    end
  end
end
