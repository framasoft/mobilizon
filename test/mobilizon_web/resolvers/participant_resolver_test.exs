defmodule MobilizonWeb.Resolvers.ParticipantResolverTest do
  use MobilizonWeb.ConnCase
  alias Mobilizon.Events
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  @event %{
    description: "some body",
    title: "some title",
    begins_on:
      DateTime.utc_now()
      |> DateTime.truncate(:second),
    uuid: "b5126423-f1af-43e4-a923-002a03003ba4",
    url: "some url",
    category: "meeting",
    options: %{}
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
      assert json_response(res, 200)["data"]["joinEvent"]["role"] == "PARTICIPANT"
      assert json_response(res, 200)["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert json_response(res, 200)["data"]["joinEvent"]["actor"]["id"] == to_string(actor.id)

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

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Event with this ID \"1042\" doesn't exist"
    end

    test "actor_leave_event/3 should delete a participant from an event", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      event = insert(:event, %{organizer_actor: actor})
      participant = insert(:participant, %{actor: actor, event: event})
      participant2 = insert(:participant, %{event: event})

      mutation = """
          mutation {
            leaveEvent(
              actor_id: #{participant.actor.id},
              event_id: #{event.id}
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
      assert json_response(res, 200)["data"]["leaveEvent"]["event"]["id"] == to_string(event.id)

      assert json_response(res, 200)["data"]["leaveEvent"]["actor"]["id"] ==
               to_string(participant.actor.id)

      query = """
      {
        event(uuid: "#{event.uuid}") {
          participants {
            role,
            actor {
                preferredUsername
            }
          }
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "participants"))

      assert json_response(res, 200)["data"]["event"]["participants"] == [
               %{
                 "actor" => %{
                   "preferredUsername" => participant2.actor.preferred_username
                 },
                 "role" => "CREATOR"
               }
             ]
    end

    test "actor_leave_event/3 should check if the participant is the only creator", %{
      conn: conn,
      actor: actor,
      user: user
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

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You can't leave event because you're the only event creator participant"

      # If we have a second participant but not an event creator
      insert(:participant, %{event: participant.event, role: :participant})

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

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "You can't leave event because you're the only event creator participant"
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
      event = insert(:event)
      participant = insert(:participant, %{actor: actor})

      mutation = """
          mutation {
            leaveEvent(
              actor_id: #{participant.actor.id},
              event_id: #{event.id}
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
      event =
        @event
        |> Map.put(:organizer_actor_id, context.actor.id)

      {:ok, event} = Events.create_event(event)

      query = """
      {
        event(uuid: "#{event.uuid}") {
          participants(roles: "participant,moderator,administrator,creator") {
            role,
            actor {
                preferredUsername
            }
          }
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "participants"))

      assert json_response(res, 200)["data"]["event"]["participants"] == [
               %{
                 "actor" => %{
                   "preferredUsername" => context.actor.preferred_username
                 },
                 "role" => "CREATOR"
               }
             ]

      # Adding two participants
      actor2 = insert(:actor)
      actor3 = insert(:actor)
      # This one won't get listed (as not approved)
      insert(:participant, event: event, actor: actor2, role: :not_approved)
      # This one will (as a participant)
      participant2 = insert(:participant, event: event, actor: actor3, role: :participant)

      query = """
      {
        event(uuid: "#{event.uuid}") {
          participants(page: 1, limit: 1, roles: "participant,moderator,administrator,creator") {
            role,
            actor {
                preferredUsername
            }
          }
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "participants"))

      sorted_participants =
        json_response(res, 200)["data"]["event"]["participants"]
        |> Enum.sort_by(
          &(&1
            |> Map.get("actor")
            |> Map.get("preferredUsername"))
        )

      assert sorted_participants == [
               %{
                 "actor" => %{
                   "preferredUsername" => participant2.actor.preferred_username
                 },
                 "role" => "PARTICIPANT"
               }
             ]

      query = """
      {
        event(uuid: "#{event.uuid}") {
          participants(page: 2, limit: 1, roles: "participant,moderator,administrator,creator") {
            role,
            actor {
                preferredUsername
            }
          }
        }
      }
      """

      res =
        context.conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "participants"))

      sorted_participants =
        json_response(res, 200)["data"]["event"]["participants"]
        |> Enum.sort_by(
          &(&1
            |> Map.get("actor")
            |> Map.get("preferredUsername"))
        )

      assert sorted_participants == [
               %{
                 "actor" => %{
                   "preferredUsername" => context.actor.preferred_username
                 },
                 "role" => "CREATOR"
               }
             ]
    end

    test "stats_participants_for_event/3 give the number of (un)approved participants", %{
      conn: conn,
      actor: actor
    } do
      event =
        @event
        |> Map.put(:organizer_actor_id, actor.id)

      {:ok, event} = Events.create_event(event)

      query = """
      {
        event(uuid: "#{event.uuid}") {
          uuid,
          participantStats {
            approved,
            unapproved
          }
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["event"]["uuid"] == to_string(event.uuid)
      assert json_response(res, 200)["data"]["event"]["participantStats"]["approved"] == 1
      assert json_response(res, 200)["data"]["event"]["participantStats"]["unapproved"] == 0

      moderator = insert(:actor)

      Events.create_participant(%{
        role: :moderator,
        event_id: event.id,
        actor_id: moderator.id
      })

      unapproved = insert(:actor)

      Events.create_participant(%{
        role: :not_approved,
        event_id: event.id,
        actor_id: unapproved.id
      })

      query = """
      {
        event(uuid: "#{event.uuid}") {
          uuid,
          participantStats {
            approved,
            unapproved
          }
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["event"]["uuid"] == to_string(event.uuid)
      assert json_response(res, 200)["data"]["event"]["participantStats"]["approved"] == 2
      assert json_response(res, 200)["data"]["event"]["participantStats"]["unapproved"] == 1
    end
  end

  describe "Participant approval" do
    test "accept_participation/3", %{conn: conn, actor: actor, user: user} do
      user_creator = insert(:user)
      actor_creator = insert(:actor, user: user_creator)
      event = insert(:event, join_options: :restricted, organizer_actor: actor_creator)
      insert(:participant, event: event, actor: actor_creator, role: :creator)

      mutation = """
          mutation {
            joinEvent(
              actor_id: #{actor.id},
              event_id: #{event.id}
            ) {
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
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["joinEvent"]["role"] == "NOT_APPROVED"
      assert json_response(res, 200)["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert json_response(res, 200)["data"]["joinEvent"]["actor"]["id"] == to_string(actor.id)
      participation_id = json_response(res, 200)["data"]["joinEvent"]["id"]

      mutation = """
          mutation {
            acceptParticipation(
              id: "#{participation_id}",
              moderator_actor_id: #{actor_creator.id}
            ) {
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
      """

      res =
        conn
        |> auth_conn(user_creator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["acceptParticipation"]["role"] == "PARTICIPANT"

      assert json_response(res, 200)["data"]["acceptParticipation"]["event"]["id"] ==
               to_string(event.id)

      assert json_response(res, 200)["data"]["acceptParticipation"]["actor"]["id"] ==
               to_string(actor.id)

      res =
        conn
        |> auth_conn(user_creator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] =~
               " can't be approved since it's already a participant (with role participant)"
    end

    test "accept_participation/3 with bad parameters", %{conn: conn, actor: actor, user: user} do
      user_creator = insert(:user)
      actor_creator = insert(:actor, user: user_creator)
      event = insert(:event, join_options: :restricted)
      insert(:participant, event: event, role: :creator)

      mutation = """
          mutation {
            joinEvent(
              actor_id: #{actor.id},
              event_id: #{event.id}
            ) {
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
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["joinEvent"]["role"] == "NOT_APPROVED"
      assert json_response(res, 200)["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert json_response(res, 200)["data"]["joinEvent"]["actor"]["id"] == to_string(actor.id)
      participation_id = json_response(res, 200)["data"]["joinEvent"]["id"]

      mutation = """
          mutation {
            acceptParticipation(
              id: "#{participation_id}",
              moderator_actor_id: #{actor_creator.id}
            ) {
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
      """

      res =
        conn
        |> auth_conn(user_creator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Provided moderator actor ID doesn't have permission on this event"
    end
  end

  describe "reject participation" do
    test "reject_participation/3", %{conn: conn, actor: actor, user: user} do
      user_creator = insert(:user)
      actor_creator = insert(:actor, user: user_creator)
      event = insert(:event, join_options: :restricted, organizer_actor: actor_creator)
      insert(:participant, event: event, actor: actor_creator, role: :creator)

      mutation = """
          mutation {
            joinEvent(
              actor_id: #{actor.id},
              event_id: #{event.id}
            ) {
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
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["joinEvent"]["role"] == "NOT_APPROVED"
      assert json_response(res, 200)["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert json_response(res, 200)["data"]["joinEvent"]["actor"]["id"] == to_string(actor.id)
      participation_id = json_response(res, 200)["data"]["joinEvent"]["id"]

      mutation = """
          mutation {
            rejectParticipation(
              id: "#{participation_id}",
              moderator_actor_id: #{actor_creator.id}
            ) {
                id,
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
        |> auth_conn(user_creator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["rejectParticipation"]["id"] == participation_id

      assert json_response(res, 200)["data"]["rejectParticipation"]["event"]["id"] ==
               to_string(event.id)

      assert json_response(res, 200)["data"]["rejectParticipation"]["actor"]["id"] ==
               to_string(actor.id)

      res =
        conn
        |> auth_conn(user_creator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "Participant not found"
    end

    test "reject_participation/3 with bad parameters", %{conn: conn, actor: actor, user: user} do
      user_creator = insert(:user)
      actor_creator = insert(:actor, user: user_creator)
      event = insert(:event, join_options: :restricted)
      insert(:participant, event: event, role: :creator)

      mutation = """
          mutation {
            joinEvent(
              actor_id: #{actor.id},
              event_id: #{event.id}
            ) {
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
      """

      res =
        conn
        |> auth_conn(user)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["joinEvent"]["role"] == "NOT_APPROVED"
      assert json_response(res, 200)["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert json_response(res, 200)["data"]["joinEvent"]["actor"]["id"] == to_string(actor.id)
      participation_id = json_response(res, 200)["data"]["joinEvent"]["id"]

      mutation = """
          mutation {
            rejectParticipation(
              id: "#{participation_id}",
              moderator_actor_id: #{actor_creator.id}
            ) {
                id,
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
        |> auth_conn(user_creator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Provided moderator actor ID doesn't have permission on this event"
    end
  end
end
