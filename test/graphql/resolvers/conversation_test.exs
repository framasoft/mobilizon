defmodule Mobilizon.GraphQL.Resolvers.ConversationTest do
  use Mobilizon.Web.ConnCase
  alias Mobilizon.Discussions
  alias Mobilizon.GraphQL.AbsintheHelpers
  import Mobilizon.Factory

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user, preferred_username: "test")

    {:ok, conn: conn, user: user, actor: actor}
  end

  @event_conversations_query """
  query Event($uuid: UUID!) {
    event(uuid: $uuid) {
      id
      uuid
      conversations {
        total
        elements {
          id
          lastComment {
            id
            text
          }
          comments {
            total
            elements {
              id
              text
            }
          }
          actor {
            id
            preferredUsername
          }
        }
      }
    }
  }
  """

  describe "Find conversations for event" do
    test "for a given event", %{conn: conn, user: user, actor: actor} do
      event = insert(:event, organizer_actor: actor)
      origin_comment = insert(:comment, actor: actor)
      conversation = insert(:conversation, event: event, origin_comment: origin_comment)
      another_comment = insert(:comment, origin_comment: conversation.origin_comment)

      Discussions.update_comment(conversation.origin_comment, %{conversation_id: conversation.id})
      Discussions.update_comment(another_comment, %{conversation_id: conversation.id})

      conversation_participant =
        insert(:conversation_participant, actor: actor, conversation: conversation)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @event_conversations_query,
          variables: %{uuid: conversation.event.uuid}
        )

      assert res["errors"] == nil
      assert res["data"]["event"]["uuid"] == to_string(conversation.event.uuid)
      assert res["data"]["event"]["conversations"]["total"] == 1
      conversation_data = hd(res["data"]["event"]["conversations"]["elements"])
      assert conversation_data["id"] == to_string(conversation.id)
      assert conversation_data["lastComment"]["text"] == conversation.last_comment.text

      assert conversation_data["comments"]["total"] == 2
      comments = conversation_data["comments"]["elements"]

      assert MapSet.new(Enum.map(comments, & &1["id"])) ==
               [conversation.origin_comment.id, another_comment.id]
               |> Enum.map(&to_string/1)
               |> MapSet.new()

      assert Enum.any?(comments, fn comment ->
               comment["text"] == conversation.origin_comment.text
             end)

      assert conversation_data["actor"]["preferredUsername"] ==
               conversation_participant.actor.preferred_username
    end
  end
end
