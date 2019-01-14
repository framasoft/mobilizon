defmodule MobilizonWeb.Resolvers.EventResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.{Events, Actors}
  alias Mobilizon.Actors.{Actor, User}
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  @event %{description: "some body", title: "some title", begins_on: Ecto.DateTime.utc()}

  setup %{conn: conn} do
    {:ok, %User{default_actor: %Actor{} = actor} = user} =
      Actors.register(%{email: "test@test.tld", password: "testest", username: "test"})

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Event Resolver" do
    test "find_event/3 returns an event", context do
      category = insert(:category)

      event =
        @event
        |> Map.put(:organizer_actor_id, context.actor.id)
        |> Map.put(:category_id, category.id)

      {:ok, event} = Events.create_event(event)

      query = """
      {
        event(uuid: "#{event.uuid}") {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["event"]["uuid"] == to_string(event.uuid)

      query = """
      {
        event(uuid: "bad uuid") {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert [%{"message" => "Argument \"uuid\" has invalid value \"bad uuid\"."}] =
               json_response(res, 200)["errors"]
    end

    test "list_participants_for_event/3 returns participants for an event", context do
      # Plain event
      category = insert(:category)

      event =
        @event
        |> Map.put(:organizer_actor_id, context.actor.id)
        |> Map.put(:category_id, category.id)

      {:ok, event} = Events.create_event(event)

      query = """
      {
        participants(uuid: "#{event.uuid}") {
          role,
          actor {
              preferredUsername
          }
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "participants"))

      assert json_response(res, 200)["data"]["participants"] == [
               %{
                 "actor" => %{"preferredUsername" => context.actor.preferred_username},
                 "role" => 4
               }
             ]

      # Adding a participant
      actor2 = insert(:actor)
      participant = insert(:participant, event: event, actor: actor2)

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "participants"))

      assert json_response(res, 200)["data"]["participants"] == [
               %{
                 "actor" => %{"preferredUsername" => context.actor.preferred_username},
                 "role" => 4
               },
               %{
                 "actor" => %{"preferredUsername" => participant.actor.preferred_username},
                 "role" => 0
               }
             ]
    end

    test "create_event/3 creates an event", %{conn: conn, actor: actor, user: user} do
      category = insert(:category)

      mutation = """
          mutation {
              createEvent(
                  title: "come to my event",
                  description: "it will be fine",
                  begins_on: "#{DateTime.utc_now() |> DateTime.to_iso8601()}",
                  organizer_actor_username: "#{actor.preferred_username}",
                  category: "#{category.title}",
                  address_type: #{"OTHER"}
              ) {
                title,
                uuid
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["createEvent"]["title"] == "come to my event"
    end

    test "search_events_and_actors/3 finds events and actors", %{conn: conn, actor: actor} do
      event = insert(:event, title: "test")

      query = """
      {
          search(search: "test") {
              ...on Event {
                title,
                uuid,
                __typename
              },
              ...on Actor {
                preferredUsername,
                __typename
              }
            }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

      assert hd(json_response(res, 200)["data"]["search"])["uuid"] == to_string(event.uuid)

      assert hd(tl(json_response(res, 200)["data"]["search"]))["preferredUsername"] ==
               actor.preferred_username
    end

    test "list_events/3 returns events", context do
      event = insert(:event)

      query = """
      {
        events {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["events"] |> Enum.map(& &1["uuid"]) == [event.uuid]

      Enum.each(0..15, fn _ ->
        insert(:event)
      end)

      query = """
      {
        events {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["events"] |> length == 10

      query = """
      {
        events(page: 2) {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["events"] |> length == 7

      query = """
      {
        events(page: 2, limit: 15) {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["events"] |> length == 2

      query = """
      {
        events(page: 3, limit: 15) {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["events"] |> length == 0
    end

    test "list_events/3 doesn't list private events", context do
      insert(:event, visibility: :private)
      insert(:event, visibility: :unlisted)
      insert(:event, visibility: :moderated)
      insert(:event, visibility: :invite)

      query = """
      {
        events {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["events"] |> Enum.map(& &1["uuid"]) == []
    end

    test "find_event/3 returns an unlisted event", context do
      event = insert(:event, visibility: :unlisted)

      query = """
      {
        event(uuid: "#{event.uuid}") {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["event"]["uuid"] == to_string(event.uuid)
    end

    test "find_event/3 doesn't return a private event", context do
      event = insert(:event, visibility: :private)

      query = """
      {
        event(uuid: "#{event.uuid}") {
          uuid,
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
               "Event with UUID #{event.uuid} not found"
    end
  end
end
