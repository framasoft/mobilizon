defmodule MobilizonWeb.Resolvers.PersonResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Actors
  alias MobilizonWeb.AbsintheHelpers

  @valid_actor_params %{email: "test@test.tld", password: "testest", username: "test"}
  @non_existent_username "nonexistent"

  describe "Person Resolver" do
    test "find_actor/3 returns a person by it's username", context do
      {:ok, actor} = Actors.register(@valid_actor_params)

      query = """
      {
        person(preferredUsername: "#{actor.preferred_username}") {
            preferredUsername,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "person"))

      assert json_response(res, 200)["data"]["person"]["preferredUsername"] ==
               actor.preferred_username

      query = """
      {
        person(preferredUsername: "#{@non_existent_username}") {
            preferredUsername,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "person"))

      assert json_response(res, 200)["data"]["person"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Person with name #{@non_existent_username} not found"
    end

    test "get_current_person/3 returns the current logged-in actor", context do
      {:ok, actor} = Actors.register(@valid_actor_params)

      query = """
      {
          loggedPerson {
            avatarUrl,
            preferredUsername,
          }
        }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_person"))

      assert json_response(res, 200)["data"]["loggedPerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to be logged-in to view current person"

      res =
        context.conn
        |> auth_conn(actor.user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_person"))

      assert json_response(res, 200)["data"]["loggedPerson"]["preferredUsername"] ==
               actor.preferred_username
    end
  end
end
