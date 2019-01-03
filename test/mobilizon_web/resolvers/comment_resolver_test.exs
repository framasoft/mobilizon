defmodule MobilizonWeb.Resolvers.CommentResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, User}
  alias MobilizonWeb.AbsintheHelpers

  @comment %{text: "I love this event"}

  setup %{conn: conn} do
    {:ok, %User{default_actor: %Actor{} = actor} = user} =
      Actors.register(%{email: "test@test.tld", password: "testest", username: "test"})

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Comment Resolver" do
    test "create_comment/3 creates a comment", %{conn: conn, actor: actor, user: user} do
      mutation = """
          mutation {
              createComment(
                  text: "#{@comment.text}",
                  actor_username: "#{actor.preferred_username}"
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
