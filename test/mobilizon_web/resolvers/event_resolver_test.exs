defmodule MobilizonWeb.Resolvers.EventResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Events
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  @event %{
    description: "some body",
    title: "some title",
    begins_on: DateTime.utc_now() |> DateTime.truncate(:second),
    uuid: "b5126423-f1af-43e4-a923-002a03003ba4",
    url: "some url",
    category: "meeting"
  }

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user, preferred_username: "test")

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Event Resolver" do
    test "find_event/3 returns an event", context do
      event =
        @event
        |> Map.put(:organizer_actor_id, context.actor.id)

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

    test "create_event/3 should check the organizer_actor_id is owned by the user", %{
      conn: conn,
      user: user
    } do
      another_actor = insert(:actor)

      begins_on = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      mutation = """
          mutation {
              createEvent(
                  title: "come to my event",
                  description: "it will be fine",
                  begins_on: "#{begins_on}",
                  organizer_actor_id: "#{another_actor.id}",
                  category: "birthday"
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

      assert json_response(res, 200)["data"]["createEvent"] == nil

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Organizer actor id is not owned by the user"
    end

    test "create_event/3 creates an event", %{conn: conn, actor: actor, user: user} do
      mutation = """
          mutation {
              createEvent(
                  title: "come to my event",
                  description: "it will be fine",
                  begins_on: "#{
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      }",
                  organizer_actor_id: "#{actor.id}",
                  category: "birthday"
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

    test "create_event/3 creates an event with options", %{conn: conn, actor: actor, user: user} do
      mutation = """
          mutation {
              createEvent(
                  title: "come to my event",
                  description: "it will be fine",
                  begins_on: "#{
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      }",
                  organizer_actor_id: "#{actor.id}",
                  options: {
                    maximumAttendeeCapacity: 30,
                    showRemainingAttendeeCapacity: true
                  }
              ) {
                title,
                uuid,
                options {
                  maximumAttendeeCapacity,
                  showRemainingAttendeeCapacity
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["createEvent"]["title"] == "come to my event"

      assert json_response(res, 200)["data"]["createEvent"]["options"]["maximumAttendeeCapacity"] ==
               30

      assert json_response(res, 200)["data"]["createEvent"]["options"][
               "showRemainingAttendeeCapacity"
             ] == true
    end

    test "create_event/3 creates an event with tags", %{conn: conn, actor: actor, user: user} do
      mutation = """
          mutation {
              createEvent(
                  title: "my event is referenced",
                  description: "with tags!",
                  begins_on: "#{
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      }",
                  organizer_actor_id: "#{actor.id}",
                  category: "birthday",
                  tags: ["nicolas", "birthday", "bad tag"]
              ) {
                title,
                uuid,
                tags {
                  title,
                  slug
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["createEvent"]["title"] == "my event is referenced"

      assert json_response(res, 200)["data"]["createEvent"]["tags"] == [
               %{"slug" => "nicolas", "title" => "nicolas"},
               %{"slug" => "birthday", "title" => "birthday"},
               %{"slug" => "bad-tag", "title" => "bad tag"}
             ]
    end

    test "create_event/3 creates an event with an address", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      address = insert(:address)

      mutation = """
          mutation {
              createEvent(
                  title: "my event is referenced",
                  description: "with tags!",
                  begins_on: "#{
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      }",
                  organizer_actor_id: "#{actor.id}",
                  category: "birthday",
                  physical_address: {
                    street: "#{address.street}",
                    locality: "#{address.locality}"
                  }
              ) {
                title,
                uuid,
                physicalAddress {
                  url,
                  geom,
                  street
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["createEvent"]["title"] == "my event is referenced"

      assert json_response(res, 200)["data"]["createEvent"]["physicalAddress"]["street"] ==
               address.street

      refute json_response(res, 200)["data"]["createEvent"]["physicalAddress"]["url"] ==
               address.url

      mutation = """
          mutation {
              createEvent(
                  title: "my event is referenced",
                  description: "with tags!",
                  begins_on: "#{
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      }",
                  organizer_actor_id: "#{actor.id}",
                  category: "birthday",
                  physical_address: {
                    url: "#{address.url}"
                  }
              ) {
                title,
                uuid,
                physicalAddress {
                  url,
                  geom,
                  street
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["createEvent"]["title"] == "my event is referenced"

      assert json_response(res, 200)["data"]["createEvent"]["physicalAddress"]["street"] ==
               address.street

      assert json_response(res, 200)["data"]["createEvent"]["physicalAddress"]["url"] ==
               address.url
    end

    test "create_event/3 creates an event with an attached picture", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      mutation = """
          mutation {
              createEvent(
                  title: "come to my event",
                  description: "it will be fine",
                  begins_on: "#{
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      }",
                  organizer_actor_id: "#{actor.id}",
                  category: "birthday",
                  picture: {
                    picture: {
                      name: "picture for my event",
                      alt: "A very sunny landscape",
                      file: "event.jpg",
                      actor_id: #{actor.id}
                    }
                  }
              ) {
                title,
                uuid,
                picture {
                  name,
                  url
                }
              }
            }
      """

      map = %{
        "query" => mutation,
        "event.jpg" => %Plug.Upload{
          path: "test/fixtures/picture.png",
          filename: "event.jpg"
        }
      }

      res =
        conn
        |> auth_conn(user)
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api", map)

      assert json_response(res, 200)["data"]["createEvent"]["title"] == "come to my event"

      assert json_response(res, 200)["data"]["createEvent"]["picture"]["name"] ==
               "picture for my event"
    end

    test "create_event/3 creates an event with an picture URL", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      picture = %{name: "my pic", alt: "represents something", file: "picture.png"}

      mutation = """
      mutation { uploadPicture(
              name: "#{picture.name}",
              alt: "#{picture.alt}",
              file: "#{picture.file}",
              actor_id: #{actor.id}
            ) {
                id,
                url,
                name
              }
        }
      """

      map = %{
        "query" => mutation,
        picture.file => %Plug.Upload{
          path: "test/fixtures/picture.png",
          filename: picture.file
        }
      }

      res =
        conn
        |> auth_conn(user)
        |> put_req_header("content-type", "multipart/form-data")
        |> post(
          "/api",
          map
        )

      assert json_response(res, 200)["data"]["uploadPicture"]["name"] == picture.name
      picture_id = json_response(res, 200)["data"]["uploadPicture"]["id"]

      mutation = """
          mutation {
              createEvent(
                  title: "come to my event",
                  description: "it will be fine",
                  begins_on: "#{
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      }",
                  organizer_actor_id: "#{actor.id}",
                  category: "birthday",
                  picture: {
                    picture_id: "#{picture_id}"
                  }
              ) {
                title,
                uuid,
                picture {
                  name,
                  url
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["createEvent"]["title"] == "come to my event"

      assert json_response(res, 200)["data"]["createEvent"]["picture"]["name"] == picture.name

      assert json_response(res, 200)["data"]["createEvent"]["picture"]["url"]
    end

    test "update_event/3 should check the event exists", %{conn: conn, actor: _actor, user: user} do
      mutation = """
          mutation {
              updateEvent(
                  event_id: 45,
                  title: "my event updated"
              ) {
                title,
                uuid,
                tags {
                  title,
                  slug
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "Event not found"
    end

    test "update_event/3 should check the user is an administrator", %{
      conn: conn,
      actor: _actor,
      user: user
    } do
      event = insert(:event)

      mutation = """
          mutation {
              updateEvent(
                  title: "my event updated",
                  event_id: #{event.id}
              ) {
                title,
                uuid,
                tags {
                  title,
                  slug
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "User doesn't own actor"
    end

    test "update_event/3 updates an event", %{conn: conn, actor: actor, user: user} do
      event = insert(:event, organizer_actor: actor)

      begins_on = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      mutation = """
          mutation {
              updateEvent(
                  title: "my event updated",
                  description: "description updated",
                  begins_on: "#{begins_on}",
                  event_id: #{event.id},
                  category: "birthday",
                  tags: ["tag1_updated", "tag2_updated"]
              ) {
                title,
                uuid,
                url,
                tags {
                  title,
                  slug
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["updateEvent"]["title"] == "my event updated"
      assert json_response(res, 200)["data"]["updateEvent"]["uuid"] == event.uuid
      assert json_response(res, 200)["data"]["updateEvent"]["url"] == event.url

      assert json_response(res, 200)["data"]["updateEvent"]["tags"] == [
               %{"slug" => "tag1-updated", "title" => "tag1_updated"},
               %{"slug" => "tag2-updated", "title" => "tag2_updated"}
             ]
    end

    test "update_event/3 updates an event with a new picture", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      event = insert(:event, organizer_actor: actor)

      begins_on =
        event.begins_on
        |> Timex.shift(hours: 3)
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()

      mutation = """
          mutation {
              updateEvent(
                  title: "my event updated",
                  description: "description updated",
                  begins_on: "#{begins_on}",
                  event_id: #{event.id},
                  category: "birthday",
                  picture: {
                    picture: {
                      name: "picture for my event",
                      alt: "A very sunny landscape",
                      file: "event.jpg",
                      actor_id: "#{actor.id}"
                    }
                  }
              ) {
                title,
                uuid,
                url,
                beginsOn,
                picture {
                  name,
                  url
                }
              }
          }
      """

      map = %{
        "query" => mutation,
        "event.jpg" => %Plug.Upload{
          path: "test/fixtures/picture.png",
          filename: "event.jpg"
        }
      }

      res =
        conn
        |> auth_conn(user)
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api", map)

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["updateEvent"]["title"] == "my event updated"
      assert json_response(res, 200)["data"]["updateEvent"]["uuid"] == event.uuid
      assert json_response(res, 200)["data"]["updateEvent"]["url"] == event.url

      assert json_response(res, 200)["data"]["updateEvent"]["beginsOn"] ==
               DateTime.to_iso8601(event.begins_on |> Timex.shift(hours: 3))

      assert json_response(res, 200)["data"]["updateEvent"]["picture"]["name"] ==
               "picture for my event"
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
      insert(:event, visibility: :restricted)

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

    #    test "find_event/3 doesn't return a private event", context do
    #      event = insert(:event, visibility: :private)
    #
    #      query = """
    #      {
    #        event(uuid: "#{event.uuid}") {
    #          uuid,
    #        }
    #      }
    #      """
    #
    #      res =
    #        context.conn
    #        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))
    #
    #      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
    #               "Event with UUID #{event.uuid} not found"
    #    end

    test "delete_event/3 deletes an event", %{conn: conn, user: user, actor: actor} do
      event = insert(:event, organizer_actor: actor)

      mutation = """
          mutation {
            deleteEvent(
              actor_id: #{actor.id},
              event_id: #{event.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["deleteEvent"]["id"] == to_string(event.id)

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not found"
    end

    test "delete_event/3 should check the user is authenticated", %{conn: conn, actor: actor} do
      event = insert(:event, organizer_actor: actor)

      mutation = """
          mutation {
            deleteEvent(
              actor_id: #{actor.id},
              event_id: #{event.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "logged-in"
    end

    test "delete_event/3 should check the actor id is owned by the user", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      event = insert(:event, organizer_actor: actor)

      mutation = """
          mutation {
            deleteEvent(
              actor_id: 1042,
              event_id: #{event.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not owned"
    end

    test "delete_event/3 should check the event can be deleted by the user", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      actor2 = insert(:actor)
      event = insert(:event, organizer_actor: actor2)

      mutation = """
          mutation {
            deleteEvent(
              actor_id: #{actor.id},
              event_id: #{event.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "cannot delete"
    end

    test "delete_event/3 allows a event being deleted by a moderator and creates a entry in actionLogs",
         %{
           conn: conn,
           user: _user,
           actor: _actor
         } do
      user_moderator = insert(:user, role: :moderator)
      actor_moderator = insert(:actor, user: user_moderator)

      actor2 = insert(:actor)
      event = insert(:event, organizer_actor: actor2)

      mutation = """
          mutation {
            deleteEvent(
              actor_id: #{actor_moderator.id},
              event_id: #{event.id}
            ) {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["deleteEvent"]["id"] == to_string(event.id)

      query = """
      {
        actionLogs {
          action,
          actor {
            preferredUsername
          },
          object {
            ... on Report {
              id,
              status
            },
            ... on ReportNote {
              content
            }
            ... on Event {
              id,
              title
            }
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert hd(json_response(res, 200)["data"]["actionLogs"]) == %{
               "action" => "EVENT_DELETION",
               "actor" => %{"preferredUsername" => actor_moderator.preferred_username},
               "object" => %{"title" => event.title, "id" => to_string(event.id)}
             }
    end

    test "list_related_events/3 should give related events", %{
      conn: conn,
      actor: actor
    } do
      tag1 = insert(:tag, title: "Elixir", slug: "elixir")
      tag2 = insert(:tag, title: "PostgreSQL", slug: "postgresql")

      event = insert(:event, title: "Initial event", organizer_actor: actor, tags: [tag1, tag2])

      event2 =
        insert(:event,
          title: "Event from same actor",
          organizer_actor: actor,
          visibility: :public,
          begins_on: Timex.shift(DateTime.utc_now(), days: 3)
        )

      event3 =
        insert(:event,
          title: "Event with same tags",
          tags: [tag1, tag2],
          visibility: :public,
          begins_on: Timex.shift(DateTime.utc_now(), days: 3)
        )

      query = """
      {
        event(uuid: "#{event.uuid}") {
          uuid,
          title,
          tags {
            id
          },
          related_events {
            uuid,
            title,
            tags {
              id
            }
          }
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert hd(json_response(res, 200)["data"]["event"]["related_events"])["uuid"] == event2.uuid

      assert hd(tl(json_response(res, 200)["data"]["event"]["related_events"]))["uuid"] ==
               event3.uuid
    end
  end
end
