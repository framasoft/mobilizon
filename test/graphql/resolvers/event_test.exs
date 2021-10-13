defmodule Mobilizon.Web.Resolvers.EventTest do
  use Mobilizon.Web.ConnCase
  use Bamboo.Test
  use Oban.Testing, repo: Mobilizon.Storage.Repo

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Events, Users}
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Workers
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.AbsintheHelpers

  alias Mobilizon.Web.Email

  @event %{
    description: "some body",
    title: "some title",
    begins_on: DateTime.utc_now() |> DateTime.truncate(:second),
    uuid: "b5126423-f1af-43e4-a923-002a03003ba4",
    url: "some url",
    category: "meeting"
  }

  @find_event_query """
  query Event($uuid: UUID!) {
      event(uuid: $uuid) {
        uuid,
        draft
      }
    }
  """

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user, preferred_username: "test")

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Find an event" do
    test "find_event/3 returns an event", context do
      event =
        @event
        |> Map.put(:organizer_actor_id, context.actor.id)

      {:ok, event} = Events.create_event(event)

      res =
        context.conn
        |> AbsintheHelpers.graphql_query(query: @find_event_query, variables: %{uuid: event.uuid})

      assert res["data"]["event"]["uuid"] == to_string(event.uuid)

      res =
        context.conn
        |> AbsintheHelpers.graphql_query(query: @find_event_query, variables: %{uuid: "bad uuid"})

      assert [%{"message" => "Argument \"uuid\" has invalid value $uuid."}] = res["errors"]

      res =
        context.conn
        |> AbsintheHelpers.graphql_query(
          query: @find_event_query,
          variables: %{uuid: "b5126423-f1af-43e4-a923-002a03003ba5"}
        )

      assert [%{"message" => "Event not found"}] = res["errors"]
    end
  end

  describe "create_event/3 for a regular profile" do
    @create_event_mutation """
    mutation CreateEvent(
      $title: String!,
      $description: String,
      $begins_on: DateTime!,
      $ends_on: DateTime,
      $status: EventStatus,
      $visibility: EventVisibility,
      $organizer_actor_id: ID!,
      $attributed_to_id: ID,
      $online_address: String,
      $options: EventOptionsInput,
      $draft: Boolean,
      $language: String
      ) {
      createEvent(
          title: $title,
          description: $description,
          begins_on: $begins_on,
          ends_on: $ends_on,
          status: $status,
          visibility: $visibility,
          organizer_actor_id: $organizer_actor_id,
          attributed_to_id: $attributed_to_id,
          online_address: $online_address,
          options: $options,
          draft: $draft,
          language: $language
      ) {
        id,
        uuid,
        title,
        description,
        begins_on,
        ends_on,
        status,
        visibility,
        organizer_actor {
          id
        },
        online_address,
        phone_address,
        category,
        draft
        language
        options {
          maximumAttendeeCapacity,
          showRemainingAttendeeCapacity,
          showEndTime
        }
      }
    }
    """

    test "create_event/3 should check the organizer_actor_id is owned by the user", %{
      conn: conn,
      user: user
    } do
      another_actor = insert(:actor)

      begins_on = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: %{
            title: "come to my event",
            description: "it will be fine",
            begins_on: "#{begins_on}",
            organizer_actor_id: "#{another_actor.id}"
          }
        )

      assert res["data"]["createEvent"] == nil

      assert hd(res["errors"])["message"] ==
               "Organizer profile is not owned by the user"
    end

    test "create_event/3 should check that end time is after start time", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      begins_on = DateTime.utc_now() |> DateTime.truncate(:second)
      ends_on = DateTime.add(begins_on, -2 * 3600)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: %{
            title: "come to my event",
            description: "it will be fine",
            begins_on: "#{begins_on}",
            ends_on: "#{ends_on}",
            organizer_actor_id: "#{actor.id}"
          }
        )

      assert hd(res["errors"])["message"] ==
               ["ends_on cannot be set before begins_on"]
    end

    test "create_event/3 creates an event", %{conn: conn, actor: actor, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: %{
            title: "come to my event",
            description: "it will be fine",
            begins_on: "#{DateTime.utc_now()}",
            organizer_actor_id: "#{actor.id}"
          }
        )

      assert res["data"]["createEvent"]["title"] == "come to my event"
      {id, ""} = res["data"]["createEvent"]["id"] |> Integer.parse()

      assert_enqueued(
        worker: Workers.BuildSearch,
        args: %{event_id: id, op: :insert_search_event}
      )
    end

    test "create_event/3 creates an event and escapes title", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: %{
            title:
              "My Event title <img src=\"http://placekitten.com/g/200/300\" onclick=\"alert('aaa')\" >",
            description:
              "<b>My description</b> <img src=\"http://placekitten.com/g/200/300\" onclick=\"alert('aaa')\" >",
            begins_on: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
            organizer_actor_id: "#{actor.id}"
          }
        )

      assert res["errors"] == nil

      assert res["data"]["createEvent"]["title"] ==
               "My Event title <img src=\"http://placekitten.com/g/200/300\" onclick=\"alert('aaa')\" >"

      assert res["data"]["createEvent"]["description"] ==
               "<b>My description</b> <img src=\"http://placekitten.com/g/200/300\"/>"

      {id, ""} = res["data"]["createEvent"]["id"] |> Integer.parse()

      assert_enqueued(
        worker: Workers.BuildSearch,
        args: %{event_id: id, op: :insert_search_event}
      )
    end

    test "create_event/3 creates an event as a draft", %{conn: conn, actor: actor, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: %{
            title: "come to my event",
            description: "it will be fine",
            begins_on: "#{DateTime.utc_now()}",
            organizer_actor_id: "#{actor.id}",
            draft: true
          }
        )

      assert res["data"]["createEvent"]["title"] == "come to my event"
      assert res["data"]["createEvent"]["draft"] == true

      event_uuid = res["data"]["createEvent"]["uuid"]
      event_id = res["data"]["createEvent"]["id"]
      {event_id_int, ""} = Integer.parse(event_id)

      refute_enqueued(
        worker: Workers.BuildSearch,
        args: %{event_id: event_id_int, op: :insert_search_event}
      )

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @find_event_query, variables: %{uuid: event_uuid})

      assert hd(res["errors"])["message"] =~ "not found"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @find_event_query, variables: %{uuid: event_uuid})

      assert res["errors"] == nil
      assert res["data"]["event"]["draft"] == true

      query = """
      query Person($actor_id: ID!, $event_id: ID) {
        person(id: $actor_id) {
          id,
          participations(eventId: $event_id) {
            elements {
              id,
              role,
              actor {
                id
              },
              event {
                id
              }
            }
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: query,
          variables: %{actor_id: actor.id, event_id: event_id}
        )

      assert res["errors"] == nil
      assert res["data"]["person"]["participations"]["elements"] == []
    end

    test "create_event/3 creates an event with options", %{conn: conn, actor: actor, user: user} do
      begins_on = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      ends_on = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: %{
            title: "come to my event",
            description: "it will be fine",
            begins_on: "#{begins_on}",
            ends_on: "#{ends_on}",
            status: "TENTATIVE",
            visibility: "UNLISTED",
            organizer_actor_id: "#{actor.id}",
            online_address: "toto@example.com",
            options: %{
              maximumAttendeeCapacity: 30,
              showRemainingAttendeeCapacity: true,
              showEndTime: false
            }
          }
        )

      assert res["errors"] == nil

      event = res["data"]["createEvent"]

      assert event["title"] == "come to my event"
      assert event["description"] == "it will be fine"
      assert event["begins_on"] == begins_on
      assert event["ends_on"] == ends_on
      assert event["status"] == "TENTATIVE"
      assert event["visibility"] == "UNLISTED"
      assert event["organizer_actor"]["id"] == "#{actor.id}"
      assert event["online_address"] == "toto@example.com"
      assert event["options"]["maximumAttendeeCapacity"] == 30
      assert event["options"]["showRemainingAttendeeCapacity"] == true
      assert event["options"]["showEndTime"] == false
      {event_id_int, ""} = Integer.parse(event["id"])

      assert_enqueued(
        worker: Workers.BuildSearch,
        args: %{event_id: event_id_int, op: :insert_search_event}
      )
    end

    test "create_event/3 creates an event an invalid options", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      begins_on = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: %{
            title: "come to my event",
            description: "it will be fine",
            begins_on: "#{begins_on}",
            organizer_actor_id: "#{actor.id}",
            options: %{
              maximumAttendeeCapacity: -5
            }
          }
        )

      assert hd(res["errors"])["message"] == %{
               "maximum_attendee_capacity" => ["must be greater than or equal to 0"]
             }
    end

    test "create_event/3 creates an event with tags", %{conn: conn, actor: actor, user: user} do
      mutation = """
          mutation {
              createEvent(
                  title: "my event is referenced",
                  description: "with tags!",
                  begins_on: "#{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}",
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
      address = %{street: "I am a street, please believe me", locality: "Where ever"}

      mutation = """
          mutation {
              createEvent(
                  title: "my event is referenced",
                  description: "with tags!",
                  begins_on: "#{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}",
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
                  id,
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

      address_url = json_response(res, 200)["data"]["createEvent"]["physicalAddress"]["url"]
      address_id = json_response(res, 200)["data"]["createEvent"]["physicalAddress"]["id"]

      mutation = """
          mutation {
              createEvent(
                  title: "my event is referenced",
                  description: "with tags!",
                  begins_on: "#{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}",
                  organizer_actor_id: "#{actor.id}",
                  category: "birthday",
                  physical_address: {
                    id: "#{address_id}"
                  }
              ) {
                title,
                uuid,
                physicalAddress {
                  id,
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

      assert json_response(res, 200)["data"]["createEvent"]["physicalAddress"]["id"] ==
               address_id

      assert json_response(res, 200)["data"]["createEvent"]["physicalAddress"]["url"] ==
               address_url
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
                  begins_on: "#{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}",
                  organizer_actor_id: "#{actor.id}",
                  category: "birthday",
                  picture: {
                    media: {
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

    test "create_event/3 creates an event with an picture ID", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      media = %{name: "my pic", alt: "represents something", file: "picture.png"}

      mutation = """
      mutation { uploadMedia (
              name: "#{media.name}",
              alt: "#{media.alt}",
              file: "#{media.file}"
            ) {
                id,
                url,
                name
              }
        }
      """

      map = %{
        "query" => mutation,
        media.file => %Plug.Upload{
          path: "test/fixtures/picture.png",
          filename: media.file
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

      assert json_response(res, 200)["data"]["uploadMedia"]["name"] == media.name
      media_id = json_response(res, 200)["data"]["uploadMedia"]["id"]

      mutation = """
          mutation {
              createEvent(
                  title: "come to my event",
                  description: "it will be fine",
                  begins_on: "#{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}",
                  organizer_actor_id: "#{actor.id}",
                  category: "birthday",
                  picture: {
                    media_id: "#{media_id}"
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

      assert json_response(res, 200)["data"]["createEvent"]["picture"]["name"] == media.name

      assert json_response(res, 200)["data"]["createEvent"]["picture"]["url"]
    end

    test "create_event/3 creates an event with detected language", %{
      conn: conn,
      actor: %Actor{id: actor_id},
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: %{
            title: "Come to my event",
            description: "This should be long enough to get detected",
            organizer_actor_id: actor_id,
            begins_on: "2021-07-26T09:00:00Z"
          }
        )

      assert res["errors"] == nil
      assert res["data"]["createEvent"]["language"] == "en"
    end

    test "create_event/3 creates an event with manually set language", %{
      conn: conn,
      actor: %Actor{id: actor_id},
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: %{
            title: "Come to my event",
            description: "This should be long enough to get detected",
            organizer_actor_id: actor_id,
            begins_on: "2021-07-26T09:00:00Z",
            language: "it"
          }
        )

      assert res["errors"] == nil
      assert res["data"]["createEvent"]["language"] == "it"
    end
  end

  describe "create_event/3 on behalf of a group" do
    @variables %{
      title: "come to my event",
      description: "it will be fine",
      begins_on: "2021-07-26T09:00:00Z"
    }

    test "create_event/3 should check the member has permission to create a group event", %{
      conn: conn
    } do
      %User{} = user = insert(:user)
      %Actor{id: group_id} = group = insert(:group)

      %Actor{id: member_not_approved_actor_id} =
        member_not_approved_actor = insert(:actor, user: user)

      insert(:member, parent: group, actor: member_not_approved_actor)
      %Actor{id: member_actor_id} = member_actor = insert(:actor, user: user)
      insert(:member, parent: group, actor: member_actor, role: :member)
      %Actor{id: moderator_actor_id} = moderator_actor = insert(:actor, user: user)
      insert(:member, parent: group, actor: moderator_actor, role: :moderator)
      %Actor{id: not_member_actor_id} = insert(:actor, user: user)

      variables = Map.put(@variables, :attributed_to_id, "#{group_id}")

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: Map.put(variables, :organizer_actor_id, "#{member_not_approved_actor_id}")
        )

      assert res["data"]["createEvent"] == nil

      assert hd(res["errors"])["message"] ==
               "Organizer profile doesn't have permission to create an event on behalf of this group"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: Map.put(variables, :organizer_actor_id, "#{not_member_actor_id}")
        )

      assert res["data"]["createEvent"] == nil

      assert hd(res["errors"])["message"] ==
               "Organizer profile doesn't have permission to create an event on behalf of this group"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: Map.put(variables, :organizer_actor_id, "#{member_actor_id}")
        )

      assert res["data"]["createEvent"] == nil

      assert hd(res["errors"])["message"] ==
               "Organizer profile doesn't have permission to create an event on behalf of this group"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_event_mutation,
          variables: Map.put(variables, :organizer_actor_id, "#{moderator_actor_id}")
        )

      assert res["errors"] == nil
      assert res["data"]["createEvent"] != nil
    end
  end

  @update_event_mutation """
  mutation updateEvent(
    $eventId: ID!
    $title: String
    $description: String
    $beginsOn: DateTime
    $endsOn: DateTime
    $status: EventStatus
    $visibility: EventVisibility
    $joinOptions: EventJoinOptions
    $draft: Boolean
    $tags: [String]
    $picture: MediaInput
    $onlineAddress: String
    $phoneAddress: String
    $organizerActorId: ID
    $attributedToId: ID
    $category: String
    $physicalAddress: AddressInput
    $options: EventOptionsInput
    $contacts: [Contact]
  ) {
  updateEvent(
    eventId: $eventId
    title: $title
    description: $description
    beginsOn: $beginsOn
    endsOn: $endsOn
    status: $status
    visibility: $visibility
    joinOptions: $joinOptions
    draft: $draft
    tags: $tags
    picture: $picture
    onlineAddress: $onlineAddress
    phoneAddress: $phoneAddress
    organizerActorId: $organizerActorId
    attributedToId: $attributedToId
    category: $category
    physicalAddress: $physicalAddress
    options: $options
    contacts: $contacts
  ) {
      id,
      uuid,
      url,
      title
      draft
      description
      beginsOn
      endsOn
      status
      tags {
        title,
        slug
      },
      online_address,
      phone_address,
      category,
      options {
        maximumAttendeeCapacity,
        showRemainingAttendeeCapacity
      },
      physicalAddress {
        url,
        geom,
        street
      }
      picture {
        name
      }
    }
  }
  """

  describe "update_event/3" do
    test "update_event/3 should check the event exists", %{conn: conn, actor: _actor, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: %{eventId: 45, title: "my event updated"}
        )

      assert hd(res["errors"])["message"] == "Event not found"
    end

    test "update_event/3 should check the user can change the organizer", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      event = insert(:event, organizer_actor: actor)
      actor2 = insert(:actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: %{eventId: event.id, title: "my event updated", organizerActorId: actor2.id}
        )

      assert hd(res["errors"])["message"] ==
               "You can't attribute this event to this profile."
    end

    test "update_event/3 should check the user is the organizer", %{
      conn: conn,
      actor: _actor,
      user: user
    } do
      event = insert(:event)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: %{eventId: event.id, title: "my event updated"}
        )

      assert hd(res["errors"])["message"] == "You can't edit this event."
    end

    test "update_event/3 should check the user is the organizer also when it's changed", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      event = insert(:event)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: %{eventId: event.id, title: "my event updated", organizerActorId: actor.id}
        )

      assert hd(res["errors"])["message"] == "You can't edit this event."
    end

    test "update_event/3 should check end time is after the beginning time", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      event = insert(:event, organizer_actor: actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: %{
            eventId: event.id,
            title: "my event updated",
            endsOn: event.begins_on |> DateTime.add(3600 * -2) |> DateTime.to_iso8601()
          }
        )

      assert hd(res["errors"])["message"] ==
               ["ends_on cannot be set before begins_on"]
    end

    test "update_event/3 updates an event", %{conn: conn, actor: actor, user: user} do
      event = insert(:event, organizer_actor: actor)
      creator = insert(:participant, event: event, actor: actor, role: :creator)
      participant_user = insert(:user)
      participant_actor = insert(:actor, user: participant_user)

      participant =
        insert(:participant, event: event, actor: participant_actor, role: :participant)

      address = insert(:address)

      begins_on = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      ends_on = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: %{
            eventId: event.id,
            title: "my event updated",
            description: "description updated",
            beginsOn: "#{begins_on}",
            endsOn: "#{ends_on}",
            status: "TENTATIVE",
            tags: ["tag1_updated", "tag2_updated"],
            onlineAddress: "toto@example.com",
            phoneAddress: "0000000000",
            category: "birthday",
            options: %{
              maximumAttendeeCapacity: 30,
              showRemainingAttendeeCapacity: true
            },
            physicalAddress: %{
              street: "#{address.street}",
              locality: "#{address.locality}"
            }
          }
        )

      assert res["errors"] == nil

      event_res = res["data"]["updateEvent"]

      assert event_res["title"] == "my event updated"
      assert event_res["description"] == "description updated"
      assert event_res["beginsOn"] == "#{begins_on}"
      assert event_res["endsOn"] == "#{ends_on}"
      assert event_res["status"] == "TENTATIVE"
      assert event_res["online_address"] == "toto@example.com"
      assert event_res["phone_address"] == "0000000000"
      assert event_res["category"] == "birthday"

      assert event_res["options"]["maximumAttendeeCapacity"] == 30
      assert event_res["options"]["showRemainingAttendeeCapacity"] == true

      assert event_res["uuid"] == event.uuid
      assert event_res["url"] == event.url

      assert event_res["physicalAddress"]["street"] == address.street
      refute event_res["physicalAddress"]["url"] == address.url

      assert event_res["tags"] == [
               %{"slug" => "tag1-updated", "title" => "tag1_updated"},
               %{"slug" => "tag2-updated", "title" => "tag2_updated"}
             ]

      {event_id_int, ""} = Integer.parse(event_res["id"])

      assert_enqueued(
        worker: Workers.BuildSearch,
        args: %{event_id: event_id_int, op: :update_search_event}
      )

      {:ok, new_event} = Mobilizon.Events.get_event_with_preload(event.id)

      assert_delivered_email(
        Email.Event.event_updated(
          creator,
          user.email,
          actor,
          event,
          new_event,
          MapSet.new([:title, :begins_on, :ends_on, :status, :physical_address])
        )
      )

      assert_delivered_email(
        Email.Event.event_updated(
          participant,
          participant_user.email,
          participant_actor,
          event,
          new_event,
          MapSet.new([:title, :begins_on, :ends_on, :status, :physical_address])
        )
      )
    end

    test "update_event/3 updates an event with a new picture", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      event = insert(:event, organizer_actor: actor)

      begins_on =
        event.begins_on
        |> DateTime.add(3 * 3600)
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()

      res =
        conn
        |> auth_conn(user)
        |> put_req_header("content-type", "multipart/form-data")
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: %{
            eventId: event.id,
            title: "my event updated",
            description: "description updated",
            beginsOn: "#{begins_on}",
            category: "birthday",
            picture: %{
              media: %{
                name: "picture for my event",
                alt: "A very sunny landscape",
                file: "event.jpg",
                actorId: "#{actor.id}"
              }
            }
          },
          uploads: %{
            "event.jpg" => %Plug.Upload{
              path: "test/fixtures/picture.png",
              filename: "event.jpg"
            }
          }
        )

      assert res["errors"] == nil
      assert res["data"]["updateEvent"]["title"] == "my event updated"
      assert res["data"]["updateEvent"]["uuid"] == event.uuid
      assert res["data"]["updateEvent"]["url"] == event.url

      assert res["data"]["updateEvent"]["beginsOn"] ==
               event.begins_on |> DateTime.add(3 * 3600) |> DateTime.to_iso8601()

      assert res["data"]["updateEvent"]["picture"]["name"] ==
               "picture for my event"
    end

    @person_participations_query """
    query EventPersonParticipation($actorId: ID!, $eventId: ID!) {
      person(id: $actorId) {
        id
        participations(eventId: $eventId) {
          total
          elements {
            role
            actor {
              id
            }
            event {
              id
            }
          }
        }
      }
    }
    """

    test "respects the draft status", %{conn: conn, actor: actor, user: user} do
      event = insert(:event, organizer_actor: actor, draft: true)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: %{
            eventId: event.id,
            title: "my event updated but still draft",
            draft: true
          }
        )

      assert res["data"]["updateEvent"]["draft"] == true

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @find_event_query,
          variables: %{
            uuid: event.uuid
          }
        )

      assert hd(res["errors"])["message"] =~ "not found"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @find_event_query,
          variables: %{
            uuid: event.uuid
          }
        )

      assert res["errors"] == nil
      assert res["data"]["event"]["draft"] == true

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @person_participations_query,
          variables: %{
            eventId: event.id,
            actorId: actor.id
          }
        )

      assert res["errors"] == nil
      assert res["data"]["person"]["participations"]["elements"] == []

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: %{
            eventId: event.id,
            title: "my event updated and no longer draft",
            draft: false
          }
        )

      assert res["data"]["updateEvent"]["draft"] == false

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @find_event_query,
          variables: %{
            uuid: event.uuid
          }
        )

      assert res["errors"] == nil
      assert res["data"]["event"]["draft"] == false

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @person_participations_query,
          variables: %{
            eventId: event.id,
            actorId: actor.id
          }
        )

      assert res["errors"] == nil

      assert res["data"]["person"]["participations"]["elements"] == [
               %{
                 "actor" => %{"id" => to_string(actor.id)},
                 "event" => %{"id" => to_string(event.id)},
                 "role" => "CREATOR"
               }
             ]
    end
  end

  describe "update_event/3 on behalf of a group" do
    test "should check the member has permission to update a group event", %{
      conn: conn
    } do
      %User{} = user = insert(:user)
      %Actor{id: group_id} = group = insert(:group)

      %Actor{id: member_not_approved_actor_id} =
        member_not_approved_actor = insert(:actor, user: user)

      insert(:member, parent: group, actor: member_not_approved_actor)
      %Actor{id: member_actor_id} = member_actor = insert(:actor, user: user)
      insert(:member, parent: group, actor: member_actor, role: :member)
      %Actor{id: moderator_actor_id} = moderator_actor = insert(:actor, user: user)
      insert(:member, parent: group, actor: moderator_actor, role: :moderator)

      %Actor{} = administrator_actor = insert(:actor, user: user)
      insert(:member, parent: group, actor: administrator_actor, role: :administrator)

      %Actor{id: not_member_actor_id} = not_member_actor = insert(:actor, user: user)

      %Event{} =
        event = insert(:event, attributed_to: group, organizer_actor: administrator_actor)

      variables =
        @variables
        |> Map.put(:attributed_to_id, "#{group_id}")
        |> Map.put(:eventId, to_string(event.id))

      Users.update_user_default_actor(user.id, member_not_approved_actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: Map.put(variables, :organizer_actor_id, "#{member_not_approved_actor_id}")
        )

      assert res["data"]["updateEvent"] == nil

      assert hd(res["errors"])["message"] ==
               "This profile doesn't have permission to update an event on behalf of this group"

      Users.update_user_default_actor(user.id, not_member_actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: Map.put(variables, :organizer_actor_id, "#{not_member_actor_id}")
        )

      assert res["data"]["updateEvent"] == nil

      assert hd(res["errors"])["message"] ==
               "This profile doesn't have permission to update an event on behalf of this group"

      Users.update_user_default_actor(user.id, member_actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: Map.put(variables, :organizer_actor_id, "#{member_actor_id}")
        )

      assert res["data"]["updateEvent"] == nil

      assert hd(res["errors"])["message"] ==
               "This profile doesn't have permission to update an event on behalf of this group"

      Users.update_user_default_actor(user.id, moderator_actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_event_mutation,
          variables: Map.put(variables, :organizer_actor_id, "#{moderator_actor_id}")
        )

      assert res["errors"] == nil
      assert res["data"]["updateEvent"] != nil
    end
  end

  describe "list_events/3" do
    @fetch_events_query """
    query Events($page: Int, $limit: Int) {
      events(page: $page, limit: $limit) {
        total
        elements {
          uuid
        }
      }
    }
    """

    test "list_events/3 returns events", %{conn: conn} do
      event = insert(:event)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @fetch_events_query)

      assert res["data"]["events"]["elements"] |> Enum.map(& &1["uuid"]) == [
               event.uuid
             ]

      insert(:event)
      insert(:event)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @fetch_events_query,
          variables: %{page: 1, limit: 2}
        )

      assert res["data"]["events"]["total"] == 3
      assert res["data"]["events"]["elements"] |> length == 2

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @fetch_events_query,
          variables: %{page: 2, limit: 2}
        )

      assert res["data"]["events"]["total"] == 3
      assert res["data"]["events"]["elements"] |> length == 1

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @fetch_events_query,
          variables: %{page: 3, limit: 2}
        )

      assert res["data"]["events"]["total"] == 3
      assert res["data"]["events"]["elements"] |> length == 0
    end

    test "list_events/3 doesn't list private events", %{conn: conn} do
      insert(:event, visibility: :private)
      insert(:event, visibility: :unlisted)
      insert(:event, visibility: :restricted)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @fetch_events_query)

      assert res["data"]["events"]["total"] == 0
      assert res["data"]["events"]["elements"] |> Enum.map(& &1["uuid"]) == []
    end

    test "list_events/3 doesn't list draft events", %{conn: conn} do
      insert(:event, visibility: :public, draft: true)

      res =
        conn
        |> AbsintheHelpers.graphql_query(query: @fetch_events_query)

      assert res["data"]["events"]["total"] == 0
      assert res["data"]["events"]["elements"] |> Enum.map(& &1["uuid"]) == []
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
  end

  describe "delete_event/3" do
    test "delete_event/3 deletes an event", %{conn: conn, user: user, actor: actor} do
      event = insert(:event, organizer_actor: actor)

      mutation = """
          mutation {
            deleteEvent(
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

    test "delete_event/3 should check the event can be deleted by the user", %{
      conn: conn,
      user: user,
      actor: _actor
    } do
      actor2 = insert(:actor)
      event = insert(:event, organizer_actor: actor2)

      mutation = """
          mutation {
            deleteEvent(
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
          total
          elements {
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
      }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert hd(json_response(res, 200)["data"]["actionLogs"]["elements"]) == %{
               "action" => "EVENT_DELETION",
               "actor" => %{"preferredUsername" => actor_moderator.preferred_username},
               "object" => %{"title" => event.title, "id" => to_string(event.id)}
             }
    end
  end

  describe "list_related_events/3" do
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
