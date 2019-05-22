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
            avatar {
              url
            },
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

      assert json_response(res, 200)["data"]["loggedPerson"]["avatar"]["url"] =~
               MobilizonWeb.Endpoint.url()
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
            avatar {
              url
            },
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

    test "create_person/3 with an avatar and an banner creates a new identity", context do
      user = insert(:user)
      insert(:actor, user: user)

      mutation = """
          mutation {
            createPerson(
              preferredUsername: "new_identity",
              name: "secret person",
              summary: "no-one will know who I am",
              banner: {
                picture: {
                  file: "landscape.jpg",
                  name: "irish landscape",
                  alt: "The beautiful atlantic way"
                }
              }
            ) {
              id,
              preferredUsername
              avatar {
                id,
                url
              },
              banner {
                id,
                name,
                url
              }
            }
          }
      """

      map = %{
        "query" => mutation,
        "landscape.jpg" => %Plug.Upload{
          path: "test/fixtures/picture.png",
          filename: "landscape.jpg"
        }
      }

      res =
        context.conn
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api", map)

      assert json_response(res, 200)["data"]["createPerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to be logged-in to create a new identity"

      res =
        context.conn
        |> auth_conn(user)
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api", map)

      assert json_response(res, 200)["data"]["createPerson"]["preferredUsername"] ==
               "new_identity"

      assert json_response(res, 200)["data"]["createPerson"]["banner"]["id"]

      assert json_response(res, 200)["data"]["createPerson"]["banner"]["name"] ==
               "The beautiful atlantic way"

      assert json_response(res, 200)["data"]["createPerson"]["banner"]["url"] =~
               MobilizonWeb.Endpoint.url() <> "/media/"
    end

    test "get_current_person/3 can return the events the person is going to", context do
      user = insert(:user)
      actor = insert(:actor, user: user)

      query = """
      {
          loggedPerson {
            goingToEvents {
              uuid,
              title
            }
          }
        }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_person"))

      assert json_response(res, 200)["data"]["loggedPerson"]["goingToEvents"] == []

      event = insert(:event, %{organizer_actor: actor})
      insert(:participant, %{actor: actor, event: event})

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_person"))

      assert json_response(res, 200)["data"]["loggedPerson"]["goingToEvents"] == [
               %{"title" => event.title, "uuid" => event.uuid}
             ]
    end

    test "find_person/3 can return the events an identity is going to if it's the same actor",
         context do
      user = insert(:user)
      actor = insert(:actor, user: user)
      insert(:actor, user: user)
      actor_from_other_user = insert(:actor)

      query = """
      {
        person(preferredUsername: "#{actor.preferred_username}") {
            goingToEvents {
              uuid,
              title
            }
        }
      }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "person"))

      assert json_response(res, 200)["data"]["person"]["goingToEvents"] == []

      query = """
      {
        person(preferredUsername: "#{actor_from_other_user.preferred_username}") {
            goingToEvents {
              uuid,
              title
            }
        }
      }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "person"))

      assert json_response(res, 200)["data"]["person"]["goingToEvents"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Actor id is not owned by authenticated user"
    end
  end
end
