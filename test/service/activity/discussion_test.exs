defmodule Mobilizon.Service.Activity.DiscussionTest do
  @moduledoc """
  Test the Discussion activity provider module
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Mention
  alias Mobilizon.Service.Activity.Discussion, as: DiscussionActivity
  alias Mobilizon.Service.Workers.{ActivityBuilder, LegacyNotifierBuilder}
  alias Mobilizon.Users.User

  use Mobilizon.DataCase, async: true
  use Oban.Testing, repo: Mobilizon.Storage.Repo
  import Mobilizon.Factory

  describe "handle discussion with mentions" do
    test "with no mentions" do
      %Comment{} = comment = insert(:comment)

      %Discussion{
        id: discussion_id,
        actor_id: group_id,
        creator_id: author_id,
        title: discussion_title,
        slug: discussion_slug
      } = discussion = insert(:discussion)

      assert {:ok, _} =
               DiscussionActivity.insert_activity(%Discussion{discussion | last_comment: comment},
                 subject: "discussion_created"
               )

      refute_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{op: :discussion_mention}
      )

      assert_enqueued(
        worker: ActivityBuilder,
        args: %{
          "group_id" => group_id,
          "author_id" => author_id,
          "object_id" => to_string(discussion_id),
          "object_type" => "discussion",
          "op" => "build_activity",
          "subject" => "discussion_created",
          "subject_params" => %{
            "discussion_slug" => discussion_slug,
            "discussion_title" => discussion_title
          },
          "type" => "discussion"
        }
      )
    end

    test "with some mentions" do
      %User{} = user = insert(:user)
      %Actor{id: actor_id} = actor = insert(:actor, user: user)

      %Comment{actor_id: author_id} = comment = insert(:comment, text: "Hey @you")

      comment = %Comment{
        comment
        | mentions: [
            %Mention{actor: actor, comment: comment, actor_id: actor_id}
          ]
      }

      %Discussion{
        id: discussion_id,
        actor_id: group_id,
        creator_id: discussion_author_id,
        title: discussion_title,
        slug: discussion_slug
      } = discussion = insert(:discussion)

      assert {:ok, _} =
               DiscussionActivity.insert_activity(%Discussion{discussion | last_comment: comment},
                 subject: "discussion_created"
               )

      assert_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => author_id,
          "group_id" => group_id,
          "mentions" => [actor_id],
          "object_id" => to_string(discussion_id),
          "object_type" => "discussion",
          "op" => "legacy_notify",
          "subject" => "discussion_mention",
          "subject_params" => %{
            "discussion_slug" => discussion_slug,
            "discussion_title" => discussion_title
          },
          "type" => "discussion"
        }
      )

      assert_enqueued(
        worker: ActivityBuilder,
        args: %{
          "group_id" => group_id,
          "author_id" => discussion_author_id,
          "object_id" => to_string(discussion_id),
          "object_type" => "discussion",
          "op" => "build_activity",
          "subject" => "discussion_created",
          "subject_params" => %{
            "discussion_slug" => discussion_slug,
            "discussion_title" => discussion_title
          },
          "type" => "discussion"
        }
      )
    end
  end
end
