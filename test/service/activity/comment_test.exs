defmodule Mobilizon.Service.Activity.CommentTest do
  @moduledoc """
  Test the Comment activity provider module
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Mention
  alias Mobilizon.Service.Activity.Comment, as: CommentActivity
  alias Mobilizon.Service.Workers.LegacyNotifierBuilder
  alias Mobilizon.Users.User

  use Mobilizon.DataCase, async: true
  use Oban.Testing, repo: Mobilizon.Storage.Repo
  import Mobilizon.Factory

  describe "handle comment with mentions" do
    test "with no mentions" do
      %Event{title: event_title, uuid: event_uuid} = event = insert(:event)
      %Comment{id: comment_id, actor_id: author_id} = comment = insert(:comment, event: event)

      assert [organizer: :enqueued, announcement: :skipped, mentionned: :skipped] ==
               CommentActivity.insert_activity(comment)

      refute_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{op: :event_comment_mention}
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
            "event_title" => event_title,
            "event_uuid" => event_uuid,
            "comment_reply_to" => false
          },
          "type" => "comment"
        }
      )
    end

    test "with some mentions" do
      %User{} = user = insert(:user)
      %Actor{id: actor_id} = actor = insert(:actor, user: user)
      %Event{uuid: event_uuid, title: event_title} = event = insert(:event)

      %Comment{id: comment_id, actor_id: author_id} =
        comment = insert(:comment, text: "Hey @you", event: event)

      comment = %Comment{
        comment
        | mentions: [
            %Mention{actor: actor, event: event, comment: comment, actor_id: actor_id}
          ]
      }

      assert [organizer: :enqueued, announcement: :skipped, mentionned: :enqueued] ==
               CommentActivity.insert_activity(comment)

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => author_id,
          "mentions" => [actor_id],
          "object_id" => to_string(comment_id),
          "object_type" => "comment",
          "op" => "legacy_notify",
          "subject" => "event_comment_mention",
          "subject_params" => %{
            "event_title" => event_title,
            "event_uuid" => event_uuid
          },
          "type" => "comment"
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
            "event_title" => event_title,
            "event_uuid" => event_uuid,
            "comment_reply_to" => false
          },
          "type" => "comment"
        }
      )
    end
  end

  describe "handle comment which is an announcement" do
    test "schedules a notification for the participants" do
      %Event{uuid: event_uuid, title: event_title, id: event_id} = event = insert(:event)

      %Comment{id: comment_id, actor_id: author_id} =
        comment = insert(:comment, text: "Hey you", event: event, is_announcement: true)

      assert [organizer: :enqueued, announcement: :enqueued, mentionned: :skipped] ==
               CommentActivity.insert_activity(comment)

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => author_id,
          "object_id" => to_string(comment_id),
          "object_type" => "comment",
          "op" => "legacy_notify",
          "subject" => "participation_event_comment",
          "subject_params" => %{
            "event_title" => event_title,
            "event_uuid" => event_uuid,
            "event_id" => event_id
          },
          "type" => "comment"
        }
      )
    end
  end
end
