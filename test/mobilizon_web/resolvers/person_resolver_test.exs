defmodule MobilizonWeb.Resolvers.PersonResolverTest do
  use MobilizonWeb.ConnCase
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  @non_existent_username "nonexistent"

  describe "Person Resolver" do
    test "find_person/3 returns a person by it's username", context do
      user = insert(:user)
      actor = insert(:actor, user: user)

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
      user = insert(:user)
      actor = insert(:actor, user: user)

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
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_person"))

      assert json_response(res, 200)["data"]["loggedPerson"]["preferredUsername"] ==
               actor.preferred_username
    end

    test "create_person/3 creates a new identity", context do
      user = insert(:user)
      actor = insert(:actor, user: user)

      mutation = """
          mutation {
            createPerson(
              preferredUsername: "new_identity",
              name: "secret person",
              summary: "no-one will know who I am"
            ) {
              id,
              preferredUsername
            }
          }
      """

      res =
        context.conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["createPerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to be logged-in to create a new identity"

      res =
        context.conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["createPerson"]["preferredUsername"] ==
               "new_identity"

      query = """
      {
          identities {
            avatarUrl,
            preferredUsername,
          }
        }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "identities"))

      assert json_response(res, 200)["data"]["identities"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to be logged-in to view your list of identities"

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "identities"))

      assert json_response(res, 200)["data"]["identities"]
             |> Enum.map(fn identity -> Map.get(identity, "preferredUsername") end)
             |> MapSet.new() ==
               MapSet.new([actor.preferred_username, "new_identity"])
    end
  end
end
