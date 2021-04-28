defmodule Mobilizon.GraphQL.Resolvers.PersonTest do
  use Oban.Testing, repo: Mobilizon.Storage.Repo
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Workers

  alias Mobilizon.GraphQL.AbsintheHelpers

  alias Mobilizon.Web.Endpoint

  @non_existent_username "nonexistent"

  describe "Person Resolver" do
    @get_person_query """
    query Person($id: ID!) {
        person(id: $id) {
            preferredUsername,
        }
      }
    """

    @fetch_person_query """
    query FetchPerson($preferredUsername: String!) {
        fetchPerson(preferredUsername: $preferredUsername) {
            preferredUsername,
        }
      }
    """

    test "get_person/3 returns a person by its username", %{conn: conn} do
      user = insert(:user)
      actor = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @get_person_query, variables: %{id: actor.id})

      assert is_nil(res["errors"])

      assert res["data"]["person"]["preferredUsername"] ==
               actor.preferred_username

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @get_person_query, variables: %{id: "6895567"})

      assert res["data"]["person"] == nil

      assert hd(res["errors"])["message"] ==
               "Person with ID 6895567 not found"
    end

    test "find_person/3 returns a person by its username", context do
      user = insert(:user)
      actor = insert(:actor, user: user)

      res =
        context.conn
        |> AbsintheHelpers.graphql_query(
          query: @fetch_person_query,
          variables: %{preferredUsername: actor.preferred_username}
        )

      assert hd(res["errors"])["message"] == "You need to be logged in"
      assert hd(res["errors"])["status_code"] == 401

      res =
        context.conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @fetch_person_query,
          variables: %{preferredUsername: actor.preferred_username}
        )

      assert res["data"]["fetchPerson"]["preferredUsername"] ==
               actor.preferred_username

      res =
        context.conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @fetch_person_query,
          variables: %{preferredUsername: @non_existent_username}
        )

      assert res["data"]["fetchPerson"] == nil

      assert hd(res["errors"])["message"] ==
               "Person with username #{@non_existent_username} not found"
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
               "You need to be logged in"

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_person"))

      assert json_response(res, 200)["data"]["loggedPerson"]["preferredUsername"] ==
               actor.preferred_username

      assert json_response(res, 200)["data"]["loggedPerson"]["avatar"]["url"] =~ Endpoint.url()
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
               "You need to be logged in"

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
               "You need to be logged in"

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
                media: {
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
               "You need to be logged in"

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
               Endpoint.url() <> "/media/"
    end

    test "update_person/3 updates an existing identity", context do
      user = insert(:user)
      %Actor{id: person_id} = insert(:actor, user: user, preferred_username: "riri")

      mutation = """
          mutation {
            updatePerson(
              id: "#{person_id}",
              name: "riri updated",
              summary: "summary updated",
              banner: {
                media: {
                  file: "landscape.jpg",
                  name: "irish landscape",
                  alt: "The beautiful atlantic way"
                }
              }
            ) {
              id,
              preferredUsername,
              name,
              summary,
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

      assert json_response(res, 200)["data"]["updatePerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You need to be logged in"

      res =
        context.conn
        |> auth_conn(user)
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api", map)

      res_person = json_response(res, 200)["data"]["updatePerson"]

      assert res_person["preferredUsername"] == "riri"
      assert res_person["name"] == "riri updated"
      assert res_person["summary"] == "summary updated"

      assert res_person["banner"]["id"]
      assert res_person["banner"]["name"] == "The beautiful atlantic way"
      assert res_person["banner"]["url"] =~ Endpoint.url() <> "/media/"
    end

    test "update_person/3 should fail to update a not owned identity", context do
      user1 = insert(:user)
      user2 = insert(:user)
      %Actor{id: person_id} = insert(:actor, user: user2, preferred_username: "riri")

      mutation = """
          mutation {
            updatePerson(
              id: "#{person_id}",
              name: "riri updated",
            ) {
              id,
            }
          }
      """

      res =
        context.conn
        |> auth_conn(user1)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["updatePerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Profile is not owned by authenticated user"
    end

    test "update_person/3 should fail to update a not existing identity", context do
      user = insert(:user)
      insert(:actor, user: user, preferred_username: "riri")

      mutation = """
          mutation {
            updatePerson(
              id: "48918",
              name: "riri updated",
            ) {
              id,
            }
          }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["updatePerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Profile not found"
    end

    test "delete_person/3 should fail to update a not owned identity", context do
      user1 = insert(:user)
      user2 = insert(:user)
      %Actor{id: person_id} = insert(:actor, user: user2, preferred_username: "riri")

      mutation = """
          mutation {
            deletePerson(id: "#{person_id}") {
              id,
            }
          }
      """

      res =
        context.conn
        |> auth_conn(user1)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["deletePerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Profile is not owned by authenticated user"
    end

    test "delete_person/3 should fail to delete a not existing identity", context do
      user = insert(:user)
      insert(:actor, user: user, preferred_username: "riri")

      mutation = """
          mutation {
            deletePerson(id: "9798665") {
              id,
            }
          }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["deletePerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Profile not found"
    end

    test "delete_person/3 should fail to delete the last user identity", context do
      user = insert(:user)
      %Actor{id: person_id} = insert(:actor, user: user, preferred_username: "riri")

      mutation = """
          mutation {
            deletePerson(id: "#{person_id}") {
              id,
            }
          }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["deletePerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Cannot remove the last identity of a user"
    end

    test "delete_person/3 should fail to delete an identity that is the last admin of a group",
         context do
      group = insert(:group)
      classic_user = insert(:user)
      classic_actor = insert(:actor, user: classic_user, preferred_username: "classic_user")

      admin_user = insert(:user)
      admin_actor = insert(:actor, user: admin_user, preferred_username: "last_admin")
      insert(:actor, user: admin_user)

      insert(:member, %{actor: admin_actor, role: :creator, parent: group})
      insert(:member, %{actor: classic_actor, role: :member, parent: group})

      mutation = """
          mutation {
            deletePerson(id: "#{admin_actor.id}") {
              id,
            }
          }
      """

      res =
        context.conn
        |> auth_conn(admin_user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["deletePerson"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Cannot remove the last administrator of a group"
    end

    test "delete_person/3 should delete an actor identity", context do
      user = insert(:user)
      %Actor{id: person_id} = insert(:actor, user: user, preferred_username: "riri")
      insert(:actor, user: user, preferred_username: "fifi")

      mutation = """
          mutation {
            deletePerson(id: "#{person_id}") {
              id,
            }
          }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil

      assert_enqueued(
        worker: Workers.Background,
        args: %{
          "actor_id" => person_id,
          "op" => "delete_actor",
          "author_id" => nil,
          "suspension" => false,
          "reserve_username" => true
        }
      )

      assert %{success: 1, failure: 0} == Oban.drain_queue(queue: :background)

      query = """
      {
        person(id: "#{person_id}") {
          id,
        }
      }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "person"))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Person with ID #{person_id} not found"
    end
  end

  describe "get_current_person/3" do
    test "get_current_person/3 can return the events the person is going to", context do
      user = insert(:user)
      actor = insert(:actor, user: user)

      query = """
      {
          loggedPerson {
            participations {
              elements {
                event {
                  uuid,
                  title
                }
              }
            }
          }
        }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_person"))

      assert json_response(res, 200)["data"]["loggedPerson"]["participations"]["elements"] == []

      event = insert(:event, %{organizer_actor: actor})
      insert(:participant, %{actor: actor, event: event})

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "logged_person"))

      assert json_response(res, 200)["data"]["loggedPerson"]["participations"]["elements"] == [
               %{"event" => %{"title" => event.title, "uuid" => event.uuid}}
             ]
    end

    @person_participations """
    query PersonParticipations($actorId: ID!) {
      person(id: $actorId) {
          participations {
            total,
            elements {
              event {
                uuid,
                title
              }
            }
          }
      }
    }
    """

    test "find_person/3 can return the events an identity is going to if it's the same actor",
         context do
      user = insert(:user)
      actor = insert(:actor, user: user)
      insert(:actor, user: user)
      actor_from_other_user = insert(:actor)

      res =
        context.conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @person_participations,
          variables: %{actorId: actor.id}
        )

      assert res["data"]["person"]["participations"]["elements"] == []

      res =
        context.conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @person_participations,
          variables: %{actorId: actor_from_other_user.id}
        )

      assert res["data"]["person"]["participations"]["elements"] == nil

      assert hd(res["errors"])["message"] ==
               "Profile is not owned by authenticated user"
    end

    test "find_person/3 can return the participation for an identity on a specific event",
         context do
      user = insert(:user)
      actor = insert(:actor, user: user)
      event = insert(:event, organizer_actor: actor)
      insert(:participant, event: event, actor: actor)

      query = """
      {
        person(id: "#{actor.id}") {
            participations(eventId: "#{event.id}") {
              elements {
                event {
                  uuid,
                  title
                }
              }
            }
        }
      }
      """

      res =
        context.conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "person"))

      assert json_response(res, 200)["data"]["person"]["participations"]["elements"] == [
               %{
                 "event" => %{
                   "uuid" => event.uuid,
                   "title" => event.title
                 }
               }
             ]
    end
  end

  describe "suspend_profile/3" do
    @suspend_profile_mutation """
    mutation SuspendProfile($id: ID!) {
      suspendProfile(id: $id) {
        id
      }
    }
    """

    @person_query """
    query Person($id: ID!) {
        person(id: $id) {
          id,
          suspended
        }
      }
    """

    @moderation_logs_query """
    {
      actionLogs {
        total
        elements {
          action,
          actor {
            id,
            preferredUsername
          },
          object {
            ...on Person {
              id,
              preferredUsername
            }
          }
        }
      }
    }
    """

    test "suspends a remote profile", %{conn: conn} do
      modo = insert(:user, role: :moderator)
      %Actor{id: modo_actor_id} = insert(:actor, user: modo)
      %Actor{id: remote_profile_id} = insert(:actor, domain: "mobilizon.org", user: nil)

      res =
        conn
        |> auth_conn(modo)
        |> AbsintheHelpers.graphql_query(
          query: @suspend_profile_mutation,
          variables: %{id: remote_profile_id}
        )

      assert is_nil(res["errors"])
      assert res["data"]["suspendProfile"]["id"] == to_string(remote_profile_id)

      assert %{success: 1, failure: 0} == Oban.drain_queue(queue: :background)

      res =
        conn
        |> auth_conn(modo)
        |> AbsintheHelpers.graphql_query(
          query: @person_query,
          variables: %{id: remote_profile_id}
        )

      assert res["data"]["person"]["suspended"] == true

      res =
        conn
        |> auth_conn(modo)
        |> AbsintheHelpers.graphql_query(query: @moderation_logs_query)

      actionlog = hd(res["data"]["actionLogs"]["elements"])
      refute is_nil(actionlog)
      assert actionlog["action"] == "ACTOR_SUSPENSION"
      assert actionlog["actor"]["id"] == to_string(modo_actor_id)
      assert actionlog["object"]["id"] == to_string(remote_profile_id)
    end

    test "doesn't suspend if profile is local", %{conn: conn} do
      modo = insert(:user, role: :moderator)
      %Actor{} = insert(:actor, user: modo)
      %Actor{id: profile_id} = insert(:actor)

      res =
        conn
        |> auth_conn(modo)
        |> AbsintheHelpers.graphql_query(
          query: @suspend_profile_mutation,
          variables: %{id: profile_id}
        )

      assert hd(res["errors"])["message"] == "No remote profile found with this ID"
    end

    test "doesn't suspend if user is not at least moderator", %{conn: conn} do
      fake_modo = insert(:user)
      %Actor{} = insert(:actor, user: fake_modo)
      %Actor{id: remote_profile_id} = insert(:actor, domain: "mobilizon.org", user: nil)

      res =
        conn
        |> auth_conn(fake_modo)
        |> AbsintheHelpers.graphql_query(
          query: @suspend_profile_mutation,
          variables: %{id: remote_profile_id}
        )

      assert hd(res["errors"])["message"] ==
               "Only moderators and administrators can suspend a profile"
    end
  end
end
