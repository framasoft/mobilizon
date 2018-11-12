defmodule MobilizonWeb.Resolvers.ActorResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Actors
  alias MobilizonWeb.AbsintheHelpers

  @valid_actor_params %{email: "test@test.tld", password: "testest", username: "test"}
  @non_existent_username "nonexistent"

  describe "Actor Resolver" do
    test "find_actor/3 returns an actor by it's username", context do
      {:ok, actor} = Actors.register(@valid_actor_params)

      query = """
      {
        actor(preferredUsername: "#{actor.preferred_username}") {
            preferredUsername,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actor"))

      assert json_response(res, 200)["data"]["actor"]["preferredUsername"] ==
               actor.preferred_username

      query = """
      {
        actor(preferredUsername: "#{@non_existent_username}") {
            preferredUsername,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actor"))

      assert json_response(res, 200)["data"]["actor"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Actor with name #{@non_existent_username} not found"
    end

    test "get_current_actor/3 returns the current logged-in actor", context do
      {:ok, actor} = Actors.register(@valid_actor_params)

      query = """
      {
          loggedActor {
            avatarUrl,
            preferredUsername,
          }
        }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_actor"))

      assert json_response(res, 200)["data"]["loggedActor"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to be logged-in to view current actor"

      res =
        context.conn
        |> auth_conn(actor.user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_actor"))

      assert json_response(res, 200)["data"]["loggedActor"]["preferredUsername"] ==
               actor.preferred_username
    end
  end
end
