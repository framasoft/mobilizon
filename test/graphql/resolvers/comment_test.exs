defmodule Mobilizon.GraphQL.Resolvers.CommentTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, EventOptions}
  alias Mobilizon.GraphQL.AbsintheHelpers

  @comment_text "I love this event"

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    event = insert(:event)

    {:ok, conn: conn, actor: actor, user: user, event: event}
  end

  describe "Comment Resolver" do
    @create_comment_mutation """
    mutation CreateComment($text: String!, $eventId: ID, $inReplyToCommentId: ID) {
      createComment(text: $text, eventId: $eventId, inReplyToCommentId: $inReplyToCommentId) {
        id,
        text,
        uuid,
        inReplyToComment {
          id,
          text
        }
      }
    }
    """

    test "create_comment/3 creates a comment", %{
      conn: conn,
      actor: actor,
      user: user,
      event: event
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_comment_mutation,
          variables: %{text: @comment_text, eventId: event.id}
        )

      assert res["data"]["createComment"]["text"] == @comment_text
    end

    test "create_comment/3 doesn't allow creating events if it's disabled", %{
      conn: conn,
      actor: actor,
      user: user,
      event: event
    } do
      {:ok, %Event{options: %EventOptions{comment_moderation: :closed}}} =
        Events.update_event(event, %{options: %{comment_moderation: :closed}})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_comment_mutation,
          variables: %{text: @comment_text, eventId: event.id}
        )

      assert hd(res["errors"])["message"] ==
               "You don't have permission to do this"
    end

    test "create_comment/3 allows creating events if it's disabled but we're the organizer", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      event = insert(:event, organizer_actor: actor, options: %{comment_moderation: :closed})

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_comment_mutation,
          variables: %{text: @comment_text, eventId: event.id}
        )

      assert is_nil(res["errors"])
      assert res["data"]["createComment"]["text"] == @comment_text
    end

    test "create_comment/3 requires that the user needs to be authenticated", %{
      conn: conn,
      event: event
    } do
      actor = insert(:actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_comment_mutation,
          variables: %{text: @comment_text, eventId: event.id}
        )

      assert hd(res["errors"])["message"] ==
               "You are not allowed to create a comment if not connected"
    end

    test "create_comment/3 creates a reply to a comment", %{
      conn: conn,
      actor: actor,
      user: user,
      event: event
    } do
      comment = insert(:comment)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_comment_mutation,
          variables: %{
            text: @comment_text,
            eventId: event.id,
            inReplyToCommentId: comment.id
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["createComment"]["text"] == @comment_text
      uuid = res["data"]["createComment"]["uuid"]

      assert res["data"]["createComment"]["inReplyToComment"]["id"] ==
               to_string(comment.id)

      query = """
      query {
        thread(id: #{comment.id}) {
          text,
          uuid
        }
      }
      """

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: query, variables: %{})

      assert res["errors"] == nil
      assert res["data"]["thread"] == [%{"uuid" => uuid, "text" => @comment_text}]
    end

    @delete_comment """
      mutation DeleteComment($commentId: ID!) {
        deleteComment(commentId: $commentId) {
          id,
          deletedAt
        }
      }
    """

    test "deletes a comment", %{conn: conn, user: user, actor: actor} do
      comment = insert(:comment, actor: actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @delete_comment,
          variables: %{commentId: comment.id}
        )

      assert hd(res["errors"])["message"] ==
               "You are not allowed to delete a comment if not connected"

      # Change the current actor for user
      actor2 = insert(:actor, user: user)
      Mobilizon.Users.update_user_default_actor(user.id, actor2.id)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_comment,
          variables: %{commentId: comment.id}
        )

      assert hd(res["errors"])["message"] ==
               "You cannot delete this comment"

      Mobilizon.Users.update_user_default_actor(user.id, actor.id)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_comment,
          variables: %{commentId: comment.id}
        )

      assert res["errors"] == nil
      assert res["data"]["deleteComment"]["id"] == to_string(comment.id)
      refute is_nil(res["data"]["deleteComment"]["deletedAt"])
    end

    test "delete_comment/3 allows a comment being deleted by a moderator and creates a entry in actionLogs",
         %{
           conn: conn,
           user: _user,
           actor: _actor
         } do
      user_moderator = insert(:user, role: :moderator)
      actor_moderator = insert(:actor, user: user_moderator)

      actor2 = insert(:actor)
      comment = insert(:comment, actor: actor2)

      res =
        conn
        |> auth_conn(user_moderator)
        |> AbsintheHelpers.graphql_query(
          query: @delete_comment,
          variables: %{commentId: comment.id}
        )

      assert res["data"]["deleteComment"]["id"] == to_string(comment.id)

      query = """
      {
        actionLogs {
          total
          elements {
            action,
            actor {
              preferredUsername
            },
            object {
              ... on Report {
                id,
                status
              },
              ... on ReportNote {
                content
              }
              ... on Event {
                id,
                title
              },
              ... on Comment {
                id,
                text
              }
            }
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      refute json_response(res, 200)["errors"]

      assert hd(json_response(res, 200)["data"]["actionLogs"]["elements"]) == %{
               "action" => "COMMENT_DELETION",
               "actor" => %{"preferredUsername" => actor_moderator.preferred_username},
               "object" => %{"text" => comment.text, "id" => to_string(comment.id)}
             }
    end
  end
end
