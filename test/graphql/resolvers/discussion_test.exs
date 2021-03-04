defmodule Mobilizon.GraphQL.Resolvers.DiscussionTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.GraphQL.AbsintheHelpers

  @comment_text "What do you think?"
  @discussion_title "Hey, I'm a title!"

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    group = insert(:group)
    insert(:member, role: :member, parent: group, actor: actor)

    {:ok, conn: conn, actor: actor, user: user, group: group}
  end

  @discussion_fields_fragment """
  fragment DiscussionFields on Discussion {
    id
    title
    slug
    lastComment {
      id
      text
      insertedAt
      updatedAt
      actor {
        id
      }
    }
    actor {
      id
      domain
      name
      preferredUsername
    }
    creator {
      id
      domain
      name
      preferredUsername
    }
  }
  """

  describe "create a discussion" do
    @create_discussion_mutation """
    mutation createDiscussion($title: String!, $actorId: ID!, $text: String!) {
    createDiscussion(title: $title, text: $text, actorId: $actorId) {
      ...DiscussionFields
    }
    }
    #{@discussion_fields_fragment}
    """

    test "create_discussion/3 creates a discussion", %{
      conn: conn,
      actor: actor,
      user: user,
      group: group
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_discussion_mutation,
          variables: %{text: @comment_text, actorId: group.id, title: @discussion_title}
        )

      assert res["errors"] == nil
      assert res["data"]["createDiscussion"]["actor"]["id"] == to_string(group.id)
      assert res["data"]["createDiscussion"]["creator"]["id"] == to_string(actor.id)

      assert res["data"]["createDiscussion"]["title"] == @discussion_title
      assert res["data"]["createDiscussion"]["lastComment"]["text"] == @comment_text

      assert res["data"]["createDiscussion"]["lastComment"]["actor"]["id"] ==
               to_string(actor.id)
    end

    test "create_discussion/3 doesn't work if the actor is not a member", %{
      conn: conn,
      group: group
    } do
      user = insert(:user)
      insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_discussion_mutation,
          variables: %{text: @comment_text, actorId: group.id, title: @discussion_title}
        )

      assert hd(res["errors"])["code"] == "unauthorized"
    end

    test "create_discussion/3 doesn't work if the actor is not an approved member", %{
      conn: conn,
      group: group
    } do
      user = insert(:user)
      actor = insert(:actor, user: user)
      insert(:member, role: :invited, actor: actor, parent: group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_discussion_mutation,
          variables: %{text: @comment_text, actorId: group.id, title: @discussion_title}
        )

      assert hd(res["errors"])["code"] == "unauthorized"
    end

    test "create_discussion/3 doesn't work if the user isn't logged-in", %{
      conn: conn,
      group: group
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_discussion_mutation,
          variables: %{text: @comment_text, actorId: group.id, title: @discussion_title}
        )

      assert hd(res["errors"])["code"] == "unauthenticated"
    end
  end

  describe "reply to a discussion" do
    @reply_to_discussion_mutation """
    mutation replyToDiscussion($discussionId: ID!, $text: String!) {
      replyToDiscussion(discussionId: $discussionId, text: $text) {
        ...DiscussionFields
      }
    }
    #{@discussion_fields_fragment}
    """

    @reply_text "I agree with that."

    test "reply_to_discussion/3 replies to a discussion", %{
      conn: conn,
      actor: actor,
      group: group
    } do
      %Discussion{id: discussion_id} = insert_discussion(group, actor)

      user = insert(:user)
      actor2 = insert(:actor, user: user)
      insert(:member, role: :member, parent: group, actor: actor2)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @reply_to_discussion_mutation,
          variables: %{text: @reply_text, discussionId: discussion_id}
        )

      assert res["errors"] == nil
      assert res["data"]["replyToDiscussion"]["actor"]["id"] == to_string(group.id)
      assert res["data"]["replyToDiscussion"]["creator"]["id"] == to_string(actor.id)

      assert res["data"]["replyToDiscussion"]["lastComment"]["actor"]["id"] ==
               to_string(actor2.id)

      assert res["data"]["replyToDiscussion"]["lastComment"]["text"] == @reply_text
    end
  end

  describe "Update a discussion" do
    @update_a_discussion_mutation """
    mutation updateDiscussion($discussionId: ID!, $title: String!) {
      updateDiscussion(discussionId: $discussionId, title: $title) {
        ...DiscussionFields
      }
    }
    #{@discussion_fields_fragment}
    """

    @updated_title "New title for discussion"

    test "update_a_discussion/3 updates a discussion as original creator", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group
    } do
      %Discussion{id: discussion_id} = insert_discussion(group, actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_a_discussion_mutation,
          variables: %{title: @updated_title, discussionId: discussion_id}
        )

      assert res["errors"] == nil
      assert res["data"]["updateDiscussion"]["title"] == @updated_title
    end

    test "update_a_discussion/3 doesn't update a discussion if not member", %{
      conn: conn,
      actor: actor,
      group: group
    } do
      %Discussion{id: discussion_id} = insert_discussion(group, actor)

      user = insert(:user)
      actor2 = insert(:actor, user: user)
      insert(:member, role: :invited, parent: group, actor: actor2)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_a_discussion_mutation,
          variables: %{title: @updated_title, discussionId: discussion_id}
        )

      assert hd(res["errors"])["code"] == "unauthorized"
    end

    test "update_a_discussion/3 doesn't update a discussion if not logged in", %{
      conn: conn,
      actor: actor,
      group: group
    } do
      %Discussion{id: discussion_id} = insert_discussion(group, actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @update_a_discussion_mutation,
          variables: %{title: @updated_title, discussionId: discussion_id}
        )

      assert hd(res["errors"])["code"] == "unauthenticated"
    end
  end

  describe "Delete a discussion" do
    @delete_discussion_mutation """
    mutation deleteDiscussion($discussionId: ID!) {
      deleteDiscussion(discussionId: $discussionId) {
        id
      }
    }
    """

    test "delete_discussion/3 deletes a discussion", %{
      conn: conn,
      user: user,
      actor: actor,
      group: group
    } do
      %Discussion{id: discussion_id} = insert_discussion(group, actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_discussion_mutation,
          variables: %{discussionId: discussion_id}
        )

      assert res["errors"] == nil
      assert res["data"]["deleteDiscussion"]["id"] == to_string(discussion_id)

      assert nil == Discussions.get_discussion(discussion_id)
    end

    test "delete_discussion/3 doesn't delete a discussion if not member", %{
      conn: conn,
      actor: actor,
      group: group
    } do
      %Discussion{id: discussion_id} = insert_discussion(group, actor)

      user = insert(:user)
      actor2 = insert(:actor, user: user)
      insert(:member, role: :invited, parent: group, actor: actor2)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_discussion_mutation,
          variables: %{discussionId: discussion_id}
        )

      assert hd(res["errors"])["code"] == "unauthorized"
      refute nil == Discussions.get_discussion(discussion_id)
    end

    test "delete_discussion/3 doesn't delete a discussion if not logged in", %{
      conn: conn,
      actor: actor,
      group: group
    } do
      %Discussion{id: discussion_id} = insert_discussion(group, actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @delete_discussion_mutation,
          variables: %{discussionId: discussion_id}
        )

      assert hd(res["errors"])["code"] == "unauthenticated"
      refute nil == Discussions.get_discussion(discussion_id)
    end

    # test "create_comment/3 doesn't allow creating events if it's disabled", %{
    #   conn: conn,
    #   actor: actor,
    #   user: user,
    #   event: event
    # } do
    #   {:ok, %Event{options: %EventOptions{comment_moderation: :closed}}} =
    #     Events.update_event(event, %{options: %{comment_moderation: :closed}})

    #   res =
    #     conn
    #     |> auth_conn(user)
    #     |> AbsintheHelpers.graphql_query(
    #       query: @create_comment_mutation,
    #       variables: %{text: @comment_text, eventId: event.id}
    #     )

    #   assert hd(res["errors"])["message"] ==
    #            "You don't have permission to do this"
    # end

    # test "create_comment/3 allows creating events if it's disabled but we're the organizer", %{
    #   conn: conn,
    #   actor: actor,
    #   user: user
    # } do
    #   event = insert(:event, organizer_actor: actor, options: %{comment_moderation: :closed})

    #   res =
    #     conn
    #     |> auth_conn(user)
    #     |> AbsintheHelpers.graphql_query(
    #       query: @create_comment_mutation,
    #       variables: %{text: @comment_text, eventId: event.id}
    #     )

    #   assert is_nil(res["errors"])
    #   assert res["data"]["createComment"]["text"] == @comment_text
    # end

    # test "create_comment/3 requires that the user needs to be authenticated", %{
    #   conn: conn,
    #   event: event
    # } do
    #   actor = insert(:actor)

    #   res =
    #     conn
    #     |> AbsintheHelpers.graphql_query(
    #       query: @create_comment_mutation,
    #       variables: %{text: @comment_text, eventId: event.id}
    #     )

    #   assert hd(res["errors"])["message"] ==
    #            "You are not allowed to create a comment if not connected"
    # end

    # test "create_comment/3 creates a reply to a comment", %{
    #   conn: conn,
    #   actor: actor,
    #   user: user,
    #   event: event
    # } do
    #   comment = insert(:comment)

    #   res =
    #     conn
    #     |> auth_conn(user)
    #     |> AbsintheHelpers.graphql_query(
    #       query: @create_comment_mutation,
    #       variables: %{
    #         text: @comment_text,
    #         eventId: event.id,
    #         inReplyToCommentId: comment.id
    #       }
    #     )

    #   assert is_nil(res["errors"])
    #   assert res["data"]["createComment"]["text"] == @comment_text
    #   uuid = res["data"]["createComment"]["uuid"]

    #   assert res["data"]["createComment"]["inReplyToComment"]["id"] ==
    #            to_string(comment.id)

    #   query = """
    #   query {
    #     thread(id: #{comment.id}) {
    #       text,
    #       uuid
    #     }
    #   }
    #   """

    #   res =
    #     conn
    #     |> auth_conn(user)
    #     |> AbsintheHelpers.graphql_query(query: query, variables: %{})

    #   assert res["errors"] == nil
    #   assert res["data"]["thread"] == [%{"uuid" => uuid, "text" => @comment_text}]
    # end

    # @delete_comment """
    #   mutation DeleteComment($commentId: ID!) {
    #     deleteComment(commentId: $commentId) {
    #       id,
    #       deletedAt
    #     }
    #   }
    # """

    # test "deletes a comment", %{conn: conn, user: user, actor: actor} do
    #   comment = insert(:comment, actor: actor)

    #   res =
    #     conn
    #     |> AbsintheHelpers.graphql_query(
    #       query: @delete_comment,
    #       variables: %{commentId: comment.id}
    #     )

    #   assert hd(res["errors"])["message"] ==
    #            "You are not allowed to delete a comment if not connected"

    #   # Change the current actor for user
    #   actor2 = insert(:actor, user: user)
    #   Mobilizon.Users.update_user_default_actor(user.id, actor2.id)

    #   res =
    #     conn
    #     |> auth_conn(user)
    #     |> AbsintheHelpers.graphql_query(
    #       query: @delete_comment,
    #       variables: %{commentId: comment.id}
    #     )

    #   assert hd(res["errors"])["message"] ==
    #            "You cannot delete this comment"

    #   Mobilizon.Users.update_user_default_actor(user.id, actor.id)

    #   res =
    #     conn
    #     |> auth_conn(user)
    #     |> AbsintheHelpers.graphql_query(
    #       query: @delete_comment,
    #       variables: %{commentId: comment.id}
    #     )

    #   assert res["errors"] == nil
    #   assert res["data"]["deleteComment"]["id"] == to_string(comment.id)
    #   refute is_nil(res["data"]["deleteComment"]["deletedAt"])
    # end

    # test "delete_comment/3 allows a comment being deleted by a moderator and creates a entry in actionLogs",
    #      %{
    #        conn: conn,
    #        user: _user,
    #        actor: _actor
    #      } do
    #   user_moderator = insert(:user, role: :moderator)
    #   actor_moderator = insert(:actor, user: user_moderator)

    #   actor2 = insert(:actor)
    #   comment = insert(:comment, actor: actor2)

    #   res =
    #     conn
    #     |> auth_conn(user_moderator)
    #     |> AbsintheHelpers.graphql_query(
    #       query: @delete_comment,
    #       variables: %{commentId: comment.id}
    #     )

    #   assert res["data"]["deleteComment"]["id"] == to_string(comment.id)

    #   query = """
    #   {
    #     actionLogs {
    #       action,
    #       actor {
    #         preferredUsername
    #       },
    #       object {
    #         ... on Report {
    #           id,
    #           status
    #         },
    #         ... on ReportNote {
    #           content
    #         }
    #         ... on Event {
    #           id,
    #           title
    #         },
    #         ... on Comment {
    #           id,
    #           text
    #         }
    #       }
    #     }
    #   }
    #   """

    #   res =
    #     conn
    #     |> auth_conn(user_moderator)
    #     |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

    #   refute json_response(res, 200)["errors"]

    #   assert hd(json_response(res, 200)["data"]["actionLogs"]) == %{
    #            "action" => "COMMENT_DELETION",
    #            "actor" => %{"preferredUsername" => actor_moderator.preferred_username},
    #            "object" => %{"text" => comment.text, "id" => to_string(comment.id)}
    #          }
    # end
  end

  @spec insert_discussion(Actor.t(), Actor.t()) :: Discussion.t()
  defp insert_discussion(%Actor{type: :Group} = group, %Actor{} = actor) do
    %Comment{id: comment_id} = comment = insert(:comment)

    %Discussion{id: discussion_id} =
      discussion = insert(:discussion, creator: actor, actor: group)

    Discussions.update_comment(comment, %{discussion_id: discussion_id})

    {:ok, %Discussion{} = discussion} =
      Discussions.update_discussion(discussion, %{last_comment_id: comment_id})

    discussion
  end
end
