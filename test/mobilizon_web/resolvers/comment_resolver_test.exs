defmodule MobilizonWeb.Resolvers.CommentResolverTest do
  use MobilizonWeb.ConnCase
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  @comment %{text: "I love this event"}

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)
    event = insert(:event)

    {:ok, conn: conn, actor: actor, user: user, event: event}
  end

  describe "Comment Resolver" do
    test "create_comment/3 creates a comment", %{
      conn: conn,
      actor: actor,
      user: user,
      event: event
    } do
      mutation = """
          mutation {
              createComment(
                  text: "#{@comment.text}",
                  actor_id: "#{actor.id}",
                  event_id: "#{event.id}"
              ) {
                text,
                uuid
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: mutation, variables: %{})

      assert res["data"]["createComment"]["text"] == @comment.text
    end

    test "create_comment/3 checks that user owns actor", %{conn: conn, user: user} do
      actor = insert(:actor)

      mutation = """
          mutation {
              createComment(
                  text: "#{@comment.text}",
                  actor_id: "#{actor.id}"
              ) {
                text,
                uuid
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: mutation, variables: %{})

      assert hd(res["errors"])["message"] ==
               "Actor id is not owned by authenticated user"
    end

    test "create_comment/3 requires that the user needs to be authenticated", %{conn: conn} do
      actor = insert(:actor)

      mutation = """
          mutation {
              createComment(
                  text: "#{@comment.text}",
                  actor_id: "#{actor.id}"
              ) {
                text,
                uuid
              }
            }
      """

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: mutation, variables: %{})

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

      mutation = """
          mutation {
              createComment(
                  text: "#{@comment.text}",
                  actor_id: "#{actor.id}",
                  event_id: "#{event.id}",
                  in_reply_to_comment_id: "#{comment.id}"
              ) {
                id,
                text,
                uuid,
                in_reply_to_comment {
                  id,
                  text
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: mutation, variables: %{})

      assert res["errors"] == nil
      assert res["data"]["createComment"]["text"] == @comment.text
      uuid = res["data"]["createComment"]["uuid"]

      assert res["data"]["createComment"]["in_reply_to_comment"]["id"] ==
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
      assert res["data"]["thread"] == [%{"uuid" => uuid, "text" => @comment.text}]
    end

    @delete_comment """
      mutation DeleteComment($commentId: ID!, $actorId: ID!) {
        deleteComment(commentId: $commentId, actorId: $actorId) {
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
          variables: %{commentId: comment.id, actorId: actor.id}
        )

      assert hd(res["errors"])["message"] ==
               "You are not allowed to delete a comment if not connected"

      actor2 = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_comment,
          variables: %{commentId: comment.id, actorId: actor2.id}
        )

      assert hd(res["errors"])["message"] ==
               "You cannot delete this comment"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_comment,
          variables: %{commentId: comment.id, actorId: actor.id}
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
          variables: %{commentId: comment.id, actorId: actor_moderator.id}
        )

      assert res["data"]["deleteComment"]["id"] == to_string(comment.id)

      query = """
      {
        actionLogs {
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
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      refute json_response(res, 200)["errors"]

      assert hd(json_response(res, 200)["data"]["actionLogs"]) == %{
               "action" => "COMMENT_DELETION",
               "actor" => %{"preferredUsername" => actor_moderator.preferred_username},
               "object" => %{"text" => comment.text, "id" => to_string(comment.id)}
             }
    end
  end
end
