defmodule MobilizonWeb.Resolvers.ParticipantResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Events
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  @event %{
    description: "some body",
    title: "some title",
    begins_on: Ecto.DateTime.utc(),
    uuid: "b5126423-f1af-43e4-a923-002a03003ba4",
    url: "some url"
  }

  setup %{conn: conn} do
    user = insert(:user)
    actor = insert(:actor, user: user, preferred_username: "test")

    {:ok, conn: conn, actor: actor, user: user}
  end

  describe "Participant Resolver" do
    test "actor_join_event/3 should create a participant", %{conn: conn, user: user, actor: actor} do
      event = insert(:event)

      mutation = """
          mutation {
            joinEvent(
              actor_id: #{actor.id},
              event_id: #{event.id}
            ) {
                role,
                actor {
                  id
                },
                event {
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
      assert json_response(res, 200)["data"]["joinEvent"]["role"] == 1
      assert json_response(res, 200)["data"]["joinEvent"]["event"]["id"] == event.id
      assert json_response(res, 200)["data"]["joinEvent"]["actor"]["id"] == actor.id

      mutation = """
         mutation {
            joinEvent(
              actor_id: #{actor.id},
              event_id: #{event.id}
            ) {
                role
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "already a participant"
    end

    test "actor_join_event/3 should check the actor is owned by the user", %{
      conn: conn,
      user: user
    } do
      event = insert(:event)

      mutation = """
          mutation {
            joinEvent(
              actor_id: 1042,
              event_id: #{event.id}
            ) {
                role
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not owned"
    end

    test "actor_join_event/3 should check the event exists", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      mutation = """
          mutation {
            joinEvent(
              actor_id: #{actor.id},
              event_id: 1042
            ) {
                role
              }
            }
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~ "Event id not found"
    end

    test "actor_leave_event/3 should delete a participant from an event", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      participant = insert(:participant, %{actor: actor})

      mutation = """
          mutation {
            leaveEvent(
              actor_id: #{participant.actor.id},
              event_id: #{participant.event.id}
            ) {
                actor {
                  id
                },
                event {
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
      assert json_response(res, 200)["data"]["leaveEvent"]["event"]["id"] == participant.event.id
      assert json_response(res, 200)["data"]["leaveEvent"]["actor"]["id"] == participant.actor.id
    end

    test "actor_leave_event/3 should check the user is logged in", %{conn: conn, actor: actor} do
      participant = insert(:participant, %{actor: actor})

      mutation = """
          mutation {
            leaveEvent(
              actor_id: #{participant.actor.id},
              event_id: #{participant.event.id}
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

      assert hd(json_response(res, 200)["errors"])["message"] =~ "logged-in"
    end

    test "actor_leave_event/3 should check the actor is owned by the user", %{
      conn: conn,
      user: user
    } do
      participant = insert(:participant)

      mutation = """
          mutation {
            leaveEvent(
              actor_id: #{participant.actor.id},
              event_id: #{participant.event.id}
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

      assert hd(json_response(res, 200)["errors"])["message"] =~ "not owned"
    end

    test "actor_leave_event/3 should check the participant exists", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      participant = insert(:participant, %{actor: actor})

      mutation = """
          mutation {
            leaveEvent(
              actor_id: #{participant.actor.id},
              event_id: 1042
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

      assert hd(json_response(res, 200)["errors"])["message"] =~ "Participant not found"
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

      # Adding two participants
      actor2 = insert(:actor)
      actor3 = insert(:actor)
      # This one won't get listed (as not approved)
      participant = insert(:participant, event: event, actor: actor2, role: :not_approved)
      # This one will (as a participant)
      participant2 = insert(:participant, event: event, actor: actor3, role: :participant)

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "participants"))

      assert json_response(res, 200)["data"]["participants"] == [
               %{
                 "actor" => %{"preferredUsername" => context.actor.preferred_username},
                 "role" => "creator"
               },
               %{
                 "actor" => %{"preferredUsername" => participant2.actor.preferred_username},
                 "role" => "participant"
               }
             ]
    end
  end
end
