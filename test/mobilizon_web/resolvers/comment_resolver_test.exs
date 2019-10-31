defmodule MobilizonWeb.Resolvers.CommentResolverTest do
  use MobilizonWeb.ConnCase
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  @comment %{text: "I love this event"}

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user)

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Comment Resolver" do
    test "create_comment/3 creates a comment", %{conn: conn, actor: actor, user: user} do
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
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["createComment"]["text"] == @comment.text
    end
  end
end
