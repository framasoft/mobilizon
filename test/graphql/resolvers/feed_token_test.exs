defmodule Mobilizon.GraphQL.Resolvers.FeedTokenTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.GraphQL.AbsintheHelpers

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user, preferred_username: "test")
    insert(:actor, user: user)

    {:ok, conn: conn, actor: actor, user: user}
  end

  @user_feed_tokens_query """
  query LoggedUserFeedTokens {
    loggedUser {
      feedTokens {
        token
      }
    }
  }
  """

  @logged_person_feed_tokens_query """
  query LoggedPersonFeedTokens {
    loggedPerson {
      feedTokens {
        token
      }
    }
  }
  """

  describe "Feed Token Resolver" do
    @create_feed_token_for_actor_mutation """
    mutation CreatePersonFeedToken($actorId: ID!) {
      createFeedToken(actorId: $actorId) {
          token
          actor {
            id
          }
          user {
            id
          }
        }
      }
    """

    @create_feed_token_for_user_mutation """
    mutation CreateFeedToken {
      createFeedToken {
          token
          user {
            id
          }
        }
      }
    """

    test "create_feed_token/3 should create a feed token", %{conn: conn, user: user} do
      actor2 = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_feed_token_for_actor_mutation,
          variables: [actorId: actor2.id]
        )

      assert res["errors"] == nil
      token = res["data"]["createFeedToken"]["token"]
      assert is_binary(token)

      assert res["data"]["createFeedToken"]["user"]["id"] ==
               to_string(user.id)

      assert res["data"]["createFeedToken"]["actor"]["id"] ==
               to_string(actor2.id)

      # The token is present for the user
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @user_feed_tokens_query)

      assert res["data"]["loggedUser"] ==
               %{
                 "feedTokens" => [%{"token" => token}]
               }

      # But not for this identity
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @logged_person_feed_tokens_query)

      assert res["data"]["loggedPerson"] ==
               %{
                 "feedTokens" => []
               }

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @create_feed_token_for_user_mutation)

      assert res["errors"] == nil
      token2 = res["data"]["createFeedToken"]["token"]
      assert is_binary(token2)
      assert is_nil(res["data"]["createFeedToken"]["actor"])

      assert res["data"]["createFeedToken"]["user"]["id"] ==
               to_string(user.id)

      # The token is present for the user
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @user_feed_tokens_query)

      assert res["data"]["loggedUser"] ==
               %{
                 "feedTokens" => [%{"token" => token}, %{"token" => token2}]
               }
    end

    test "create_feed_token/3 should check the actor is owned by the user", %{
      conn: conn,
      user: user
    } do
      actor = insert(:actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_feed_token_for_actor_mutation,
          variables: [actorId: actor.id]
        )

      assert hd(res["errors"])["message"] =~ "not owned"
    end

    test "delete_feed_token/3 should delete a feed token", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      feed_token = insert(:feed_token, user: user, actor: actor)

      query = """
      {
        loggedPerson {
          feedTokens {
            token
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "loggedPerson"))

      assert json_response(res, 200)["data"]["loggedPerson"] ==
               %{
                 "feedTokens" => [
                   %{
                     "token" => ShortUUID.encode!(feed_token.token)
                   }
                 ]
               }

      mutation = """
          mutation {
            deleteFeedToken(
              token: "#{ShortUUID.encode!(feed_token.token)}",
            ) {
                actor {
                  id
                },
                user {
                  id
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["deleteFeedToken"]["user"]["id"] ==
               to_string(user.id)

      assert json_response(res, 200)["data"]["deleteFeedToken"]["actor"]["id"] ==
               to_string(actor.id)

      query = """
      {
        loggedPerson {
          feedTokens {
            token
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "loggedPerson"))

      assert json_response(res, 200)["data"]["loggedPerson"] ==
               %{
                 "feedTokens" => []
               }
    end

    test "delete_feed_token/3 should check the user is logged in", %{conn: conn} do
      mutation = """
          mutation {
            deleteFeedToken(
              token: "random",
            ) {
                actor {
                  id
                }
              }
            }
      """

      res =
        conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert "You need to be logged in" == hd(json_response(res, 200)["errors"])["message"]
    end

    test "delete_feed_token/3 should check the correct user is logged in", %{
      conn: conn,
      user: user
    } do
      user2 = insert(:user)
      feed_token = insert(:feed_token, user: user2)

      mutation = """
          mutation {
            deleteFeedToken(
              token: "#{ShortUUID.encode!(feed_token.token)}",
            ) {
                actor {
                  id
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "don't have permission"
    end

    test "delete_feed_token/3 should check the token is a valid UUID", %{
      conn: conn,
      user: user
    } do
      mutation = """
          mutation {
            deleteFeedToken(
              token: "really random"
            ) {
                actor {
                  id
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "Token is not a valid UUID"
    end

    test "delete_feed_token/3 should check the token exists", %{
      conn: conn,
      user: user
    } do
      uuid = Ecto.UUID.generate()

      mutation = """
          mutation {
            deleteFeedToken(
              token: "#{ShortUUID.encode!(uuid)}"
            ) {
                actor {
                  id
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "does not exist"
    end
  end
end
