defmodule Mobilizon.GraphQL.Resolvers.ParticipantTest do
  use Mobilizon.Web.ConnCase
  use Mobilizon.Tests.Helpers
  use Oban.Testing, repo: Mobilizon.Storage.Repo

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Config, Conversations, Events}
  alias Mobilizon.Events.{Event, EventParticipantStats, Participant}
  alias Mobilizon.GraphQL.AbsintheHelpers
  alias Mobilizon.Service.Workers.LegacyNotifierBuilder
  alias Mobilizon.Storage.Page

  import Mobilizon.Factory
  import Swoosh.TestAssertions

  @event %{
    description: "some body",
    title: "some title",
    begins_on:
      DateTime.utc_now()
      |> DateTime.truncate(:second),
    uuid: "b5126423-f1af-43e4-a923-002a03003ba4",
    url: "some url",
    category: "MEETING",
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

    test "actor_join_event/3 doesn't work if the event already has too much participants", %{
      conn: conn,
      actor: actor
    } do
      event = insert(:event, options: %{maximum_attendee_capacity: 2})
      insert(:participant, event: event, actor: actor, role: :creator)
      insert(:participant, event: event, role: :participant)
      insert(:participant, event: event, role: :not_approved)
      insert(:participant, event: event, role: :rejected)
      user_participant = insert(:user)
      actor_participant = insert(:actor, user: user_participant)

      mutation = """
          mutation {
            joinEvent(
              actor_id: #{actor_participant.id},
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
        |> auth_conn(user_participant)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["joinEvent"]["role"] == "PARTICIPANT"
      assert json_response(res, 200)["data"]["joinEvent"]["event"]["id"] == to_string(event.id)

      assert json_response(res, 200)["data"]["joinEvent"]["actor"]["id"] ==
               to_string(actor_participant.id)

      user_participant_2 = insert(:user)
      actor_participant_2 = insert(:actor, user: user_participant_2)

      mutation = """
          mutation {
            joinEvent(
              actor_id: #{actor_participant_2.id},
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
        |> auth_conn(user_participant_2)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "The event has already reached its maximum capacity"
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

    @person_participations """
    query PersonParticipations($actorId: ID!, $eventId: ID) {
      person(id: $actorId) {
          participations(eventId: $eventId) {
            total,
            elements {
              event {
                uuid,
                title
              },
              role
            }
          }
      }
    }
    """

    test "actor_leave_event/3 should delete a participant from an event", %{
      conn: conn,
      user: user,
      actor: actor
    } do
      event =
        insert(:event, %{organizer_actor: actor, participant_stats: %{creator: 1, participant: 1}})

      insert(:participant, %{actor: actor, event: event, role: :creator})
      user2 = insert(:user)
      actor2 = insert(:actor, user: user2)
      participant2 = insert(:participant, %{event: event, actor: actor2, role: :participant})

      mutation = """
          mutation {
            leaveEvent(
              actor_id: #{participant2.actor.id},
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
        |> auth_conn(user2)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["leaveEvent"]["event"]["id"] == to_string(event.id)

      assert json_response(res, 200)["data"]["leaveEvent"]["actor"]["id"] ==
               to_string(participant2.actor.id)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @person_participations,
          variables: %{actorId: actor.id, eventId: event.id}
        )

      assert res["data"]["person"]["participations"]["elements"] == [
               %{
                 "event" => %{
                   "uuid" => event.uuid,
                   "title" => event.title
                 },
                 "role" => "CREATOR"
               }
             ]

      res =
        conn
        |> auth_conn(user2)
        |> AbsintheHelpers.graphql_query(
          query: @person_participations,
          variables: %{actorId: actor2.id, eventId: event.id}
        )

      assert res["data"]["person"]["participations"]["elements"] == []
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

    test "list_participants_for_event/3 returns participants for an event", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      event =
        @event
        |> Map.put(:organizer_actor_id, actor.id)

      {:ok, event} = Events.create_event(event)

      query = """
      {
        event(uuid: "#{event.uuid}") {
          participants(roles: "participant,moderator,administrator,creator") {
            elements {
              role,
              actor {
                  preferredUsername
              }
            }
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "participants"))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["event"]["participants"]["elements"] == [
               %{
                 "actor" => %{
                   "preferredUsername" => actor.preferred_username
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
      query EventParticipants($uuid: UUID!, $roles: String, $page: Int, $limit: Int) {
        event(uuid: $uuid) {
          participants(page: $page, limit: $limit, roles: $roles) {
            total,
            elements {
              role,
              actor {
                  preferredUsername
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
          variables: %{
            uuid: event.uuid,
            roles: "participant,moderator,administrator,creator",
            page: 1,
            limit: 2
          }
        )

      assert is_nil(res["errors"])

      sorted_participants =
        res["data"]["event"]["participants"]["elements"]
        |> Enum.filter(&(&1["role"] == "CREATOR"))

      assert sorted_participants == [
               %{
                 "actor" => %{
                   "preferredUsername" => actor.preferred_username
                 },
                 "role" => "CREATOR"
               }
             ]

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: query,
          variables: %{
            uuid: event.uuid,
            actorId: actor.id,
            roles: "participant,moderator,administrator,creator",
            page: 1,
            limit: 2
          }
        )

      assert is_nil(res["errors"])

      sorted_participants =
        res["data"]["event"]["participants"]["elements"]
        |> Enum.filter(&(&1["role"] == "PARTICIPANT"))

      assert sorted_participants == [
               %{
                 "actor" => %{
                   "preferredUsername" => participant2.actor.preferred_username
                 },
                 "role" => "PARTICIPANT"
               }
             ]
    end

    test "stats_participants_for_event/3 give the number of (un)approved participants", %{
      conn: conn,
      actor: actor,
      user: user
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
            going,
            notApproved,
            rejected
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["event"]["uuid"] == to_string(event.uuid)
      assert json_response(res, 200)["data"]["event"]["participantStats"]["going"] == 1
      assert json_response(res, 200)["data"]["event"]["participantStats"]["notApproved"] == 0
      assert json_response(res, 200)["data"]["event"]["participantStats"]["rejected"] == 0

      moderator = insert(:actor)

      Events.create_participant(%{
        role: :moderator,
        event_id: event.id,
        actor_id: moderator.id
      })

      not_approved = insert(:actor)

      Events.create_participant(%{
        role: :not_approved,
        event_id: event.id,
        actor_id: not_approved.id
      })

      rejected = insert(:actor)

      Events.create_participant(%{
        role: :rejected,
        event_id: event.id,
        actor_id: rejected.id
      })

      query = """
      {
        event(uuid: "#{event.uuid}") {
          uuid,
          participantStats {
            going,
            notApproved,
            rejected
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert json_response(res, 200)["data"]["event"]["uuid"] == to_string(event.uuid)
      assert json_response(res, 200)["data"]["event"]["participantStats"]["going"] == 2
      assert json_response(res, 200)["data"]["event"]["participantStats"]["notApproved"] == 1
      assert json_response(res, 200)["data"]["event"]["participantStats"]["rejected"] == 1

      query = """
      {
        event(uuid: "#{event.uuid}") {
          uuid,
          participantStats {
            going,
            notApproved,
            rejected
          }
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "event"))

      assert is_nil(json_response(res, 200)["errors"])
      assert json_response(res, 200)["data"]["event"]["going"] == nil
    end
  end

  describe "Participation role status update" do
    test "update_participation/3", %{conn: conn, actor: actor, user: user} do
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
            updateParticipation(
              id: "#{participation_id}",
              role: PARTICIPANT,
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
      assert json_response(res, 200)["data"]["updateParticipation"]["role"] == "PARTICIPANT"

      assert json_response(res, 200)["data"]["updateParticipation"]["event"]["id"] ==
               to_string(event.id)

      assert json_response(res, 200)["data"]["updateParticipation"]["actor"]["id"] ==
               to_string(actor.id)

      assert %Participant{} = Events.get_participant(participation_id)

      assert_email_sent(to: user.email)

      res =
        conn
        |> auth_conn(user_creator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Participant already has role participant"
    end

    test "accept_participation/3 with bad parameters", %{conn: conn, actor: actor, user: user} do
      user_creator = insert(:user)
      _actor_creator = insert(:actor, user: user_creator)
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
            updateParticipation (
              id: "#{participation_id}",
              role: PARTICIPANT
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
               "Provided profile doesn't have moderator permissions on this event"
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
            updateParticipation(
              id: "#{participation_id}",
              role: REJECTED
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
      assert json_response(res, 200)["data"]["updateParticipation"]["id"] == participation_id

      assert json_response(res, 200)["data"]["updateParticipation"]["event"]["id"] ==
               to_string(event.id)

      assert json_response(res, 200)["data"]["updateParticipation"]["actor"]["id"] ==
               to_string(actor.id)

      assert %Participant{} = Events.get_participant(participation_id)
      assert_email_sent(to: user.email)

      res =
        conn
        |> auth_conn(user_creator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "Participant already has role rejected"
    end

    test "reject_participation/3 with bad parameters", %{conn: conn, actor: actor, user: user} do
      user_creator = insert(:user)
      _actor_creator = insert(:actor, user: user_creator)
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
            updateParticipation (
              id: "#{participation_id}",
              role: REJECTED
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
               "Provided profile doesn't have moderator permissions on this event"
    end
  end

  describe "Participate with anonymous user" do
    @email "test@test.tld"
    @mutation """
        mutation JoinEvent($actorId: ID!, $eventId: ID!, $email: String) {
          joinEvent(
            actorId: $actorId,
            eventId: $eventId,
            email: $email
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

    @confirmation_mutation """
      mutation ConfirmParticipation($confirmationToken: String!) {
        confirmParticipation(confirmationToken: $confirmationToken) {
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

    @cancel_participation_mutation """
      mutation LeaveEvent($actorId: ID!, $eventId: ID!, $token: String) {
          leaveEvent(
            actorId: $actorId,
            eventId: $eventId,
            token: $token
          ) {
              id
            }
          }
    """

    setup do: clear_config([:anonymous, :participation])

    setup %{conn: conn, actor: actor, user: user} do
      Mobilizon.Config.clear_config_cache()
      anonymous_actor_id = Config.anonymous_actor_id()
      {:ok, conn: conn, actor: actor, user: user, anonymous_actor_id: anonymous_actor_id}
    end

    test "I can't participate if anonymous participation is enabled on the server but disabled for this event",
         %{conn: conn, anonymous_actor_id: actor_id} do
      event = insert(:event, options: %{anonymous_participation: false})
      Config.put([:anonymous, :participation, :allowed], true)
      Config.put([:anonymous, :participation, :validation, :email, :enabled], true)
      Config.put([:anonymous, :participation, :validation, :email, :confirmation_required], false)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id}
        )

      assert hd(res["errors"])["message"] == "Anonymous participation is not enabled"
    end

    test "I can't participate if anonymous participation is enabled on the server and enabled for the event but the event is remote",
         %{conn: conn, anonymous_actor_id: actor_id} do
      event = insert(:event, options: %{anonymous_participation: true}, local: false)
      Config.put([:anonymous, :participation, :allowed], true)
      Config.put([:anonymous, :participation, :validation, :email, :enabled], true)
      Config.put([:anonymous, :participation, :validation, :email, :confirmation_required], false)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id}
        )

      assert hd(res["errors"])["message"] == "Anonymous participation is not enabled"
    end

    test "I can't participate without being logged in when using anonymous user and providing no email when required",
         %{conn: conn, anonymous_actor_id: actor_id} do
      event = insert(:event, options: %{anonymous_participation: true})
      Config.put([:anonymous, :participation, :allowed], true)
      Config.put([:anonymous, :participation, :validation, :email, :enabled], true)
      Config.put([:anonymous, :participation, :validation, :email, :confirmation_required], false)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id}
        )

      assert hd(res["errors"])["message"] == "A valid email is required by your instance"

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id, email: "bad_email"}
        )

      assert hd(res["errors"])["message"] == "A valid email is required by your instance"
    end

    test "I can participate without being logged in when using anonymous user when providing email",
         %{conn: conn, anonymous_actor_id: actor_id} do
      event = insert(:event, options: %{anonymous_participation: true})
      Config.put([:anonymous, :participation, :allowed], true)
      Config.put([:anonymous, :participation, :validation, :email, :enabled], true)
      Config.put([:anonymous, :participation, :validation, :email, :confirmation_required], false)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id, email: @email}
        )

      assert res["errors"] == nil
      assert res["data"]["joinEvent"]["role"] == "PARTICIPANT"
      assert res["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert res["data"]["joinEvent"]["actor"]["id"] == to_string(actor_id)

      %Participant{} =
        participant = event.id |> Events.list_participants_for_event() |> Map.get(:elements) |> hd

      assert participant.metadata.email == @email

      # When confirmation_required is false, participant has already the participant role
      assert participant.role == :participant

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id, email: @email}
        )

      assert hd(res["errors"])["message"] == "You are already a participant of this event"
    end

    test "Participating without being logged in when using anonymous user and providing email sends a confirmation email",
         %{conn: conn, anonymous_actor_id: actor_id} do
      event = insert(:event, options: %{anonymous_participation: true})
      Config.put([:anonymous, :participation, :allowed], true)
      Config.put([:anonymous, :participation, :validation, :email, :enabled], true)
      Config.put([:anonymous, :participation, :validation, :email, :confirmation_required], true)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id, email: @email}
        )

      assert res["errors"] == nil
      # Not approved until email confirmation
      assert res["data"]["joinEvent"]["role"] == "NOT_CONFIRMED"
      assert res["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert res["data"]["joinEvent"]["actor"]["id"] == to_string(actor_id)

      assert %Participant{
               metadata: %{confirmation_token: confirmation_token},
               role: :not_confirmed
             } = event.id |> Events.list_participants_for_event([]) |> Map.get(:elements) |> hd()

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id, email: @email}
        )

      assert hd(res["errors"])["message"] == "You are already a participant of this event"

      assert_email_sent(to: @email)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @confirmation_mutation,
          variables: %{confirmationToken: confirmation_token}
        )

      assert is_nil(res["errors"])

      assert %Participant{role: :participant} =
               event.id |> Events.list_participants_for_event() |> Map.get(:elements) |> hd()

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @confirmation_mutation,
          variables: %{confirmationToken: confirmation_token}
        )

      assert hd(res["errors"])["message"] == "Participation is already confirmed"

      assert_email_sent(to: @email)
    end

    test "I can participate anonymously and and confirm my participation with bad token",
         %{conn: conn, anonymous_actor_id: actor_id} do
      event = insert(:event, options: %{anonymous_participation: true})
      Config.put([:anonymous, :participation, :allowed], true)
      Config.put([:anonymous, :participation, :validation, :email, :enabled], true)
      Config.put([:anonymous, :participation, :validation, :email, :confirmation_required], true)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id, email: @email}
        )

      assert res["errors"] == nil
      assert res["data"]["joinEvent"]["role"] == "NOT_CONFIRMED"
      assert res["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert res["data"]["joinEvent"]["actor"]["id"] == to_string(actor_id)

      %Participant{} =
        participant =
        event.id |> Events.list_participants_for_event([]) |> Map.get(:elements) |> hd

      assert participant.metadata.email == @email

      # When confirmation_required is false, participant has already the participant role
      assert participant.role == :not_confirmed

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @confirmation_mutation,
          variables: %{confirmationToken: "bad token"}
        )

      assert hd(res["errors"])["message"] == "This token is invalid"

      assert %Participant{role: :not_confirmed} =
               event.id |> Events.list_participants_for_event([]) |> Map.get(:elements) |> hd()
    end

    test "I can participate anonymously but change my mind and cancel my participation",
         %{conn: conn, anonymous_actor_id: actor_id} do
      event = insert(:event, options: %{anonymous_participation: true})
      Config.put([:anonymous, :participation, :allowed], true)
      Config.put([:anonymous, :participation, :validation, :email, :enabled], true)
      Config.put([:anonymous, :participation, :validation, :email, :confirmation_required], true)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id, email: @email}
        )

      assert res["errors"] == nil
      assert res["data"]["joinEvent"]["role"] == "NOT_CONFIRMED"
      assert res["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert res["data"]["joinEvent"]["actor"]["id"] == to_string(actor_id)

      {:ok, %Event{participant_stats: %{not_confirmed: 1}}} = Events.get_event(event.id)

      %Participant{} =
        participant =
        event.id |> Events.list_participants_for_event([]) |> Map.get(:elements) |> hd

      assert participant.metadata.email == @email

      # When confirmation_required is false, participant has already the participant role
      assert participant.role == :not_confirmed

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @cancel_participation_mutation,
          variables: %{
            actorId: actor_id,
            eventId: event.id,
            token: "bad token"
          }
        )

      assert hd(res["errors"])["message"] == "Participant not found"

      assert %Participant{
               id: participant_id,
               role: :not_confirmed,
               metadata: %{cancellation_token: cancellation_token}
             } = event.id |> Events.list_participants_for_event([]) |> Map.get(:elements) |> hd()

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @cancel_participation_mutation,
          variables: %{
            actorId: actor_id,
            eventId: event.id,
            token: cancellation_token
          }
        )

      assert res["data"]["leaveEvent"]["id"] == participant_id

      {:ok, %Event{participant_stats: %{not_confirmed: 0}}} = Events.get_event(event.id)
      assert Events.list_participants_for_event(event.id, []) == %Page{elements: [], total: 0}
    end

    test "I can participate anonymously, confirm my participation and then be confirmed by the organizer",
         %{conn: conn, anonymous_actor_id: actor_id, actor: event_creator_actor, user: user} do
      event =
        insert(:event,
          options: %{anonymous_participation: true},
          join_options: :restricted,
          organizer_actor: event_creator_actor,
          participant_stats: %{creator: 1}
        )

      insert(:participant, event: event, actor: event_creator_actor, role: :creator)
      Config.put([:anonymous, :participation, :allowed], true)
      Config.put([:anonymous, :participation, :validation, :email, :enabled], true)
      Config.put([:anonymous, :participation, :validation, :email, :confirmation_required], true)

      assert {:ok,
              %Event{
                participant_stats: %EventParticipantStats{
                  not_confirmed: 0,
                  not_approved: 0,
                  creator: 1,
                  participant: 0
                }
              }} = Events.get_event(event.id)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @mutation,
          variables: %{actorId: actor_id, eventId: event.id, email: @email}
        )

      assert res["errors"] == nil
      assert res["data"]["joinEvent"]["role"] == "NOT_CONFIRMED"
      assert res["data"]["joinEvent"]["event"]["id"] == to_string(event.id)
      assert res["data"]["joinEvent"]["actor"]["id"] == to_string(actor_id)

      assert {:ok,
              %Event{
                participant_stats: %EventParticipantStats{
                  not_confirmed: 1,
                  not_approved: 0,
                  creator: 1,
                  participant: 0
                }
              }} = Events.get_event(event.id)

      assert %Participant{
               role: :not_confirmed,
               metadata: %{confirmation_token: confirmation_token, email: @email}
             } =
               event.id
               |> Events.list_participants_for_event([:not_confirmed])
               |> Map.get(:elements)
               |> hd

      conn
      |> AbsintheHelpers.graphql_query(
        query: @confirmation_mutation,
        variables: %{confirmationToken: confirmation_token}
      )

      assert {:ok,
              %Event{
                participant_stats: %EventParticipantStats{
                  not_confirmed: 0,
                  not_approved: 1,
                  creator: 1,
                  participant: 0
                }
              }} = Events.get_event(event.id)

      assert %Participant{role: :not_approved, id: participant_id} =
               event.id
               |> Events.list_participants_for_event([:not_approved])
               |> Map.get(:elements)
               |> hd

      update_participation_mutation = """
          mutation UpdateParticipation($participantId: ID!, $role: ParticipantRoleEnum!) {
            updateParticipation(id: $participantId, role: $role) {
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
        |> AbsintheHelpers.graphql_query(
          query: update_participation_mutation,
          variables: %{
            participantId: participant_id,
            role: "PARTICIPANT"
          }
        )

      assert res["errors"] == nil

      assert %Participant{role: :participant} =
               event.id
               |> Events.list_participants_for_event([:participant])
               |> Map.get(:elements)
               |> hd

      assert {:ok,
              %Event{
                participant_stats: %EventParticipantStats{
                  not_confirmed: 0,
                  not_approved: 0,
                  creator: 1,
                  participant: 1
                }
              }} = Events.get_event(event.id)

      assert %Participant{} = Events.get_participant(participant_id)
      assert_email_sent(to: @email)
    end
  end

  describe "Send private messages to participants" do
    @send_event_private_message_mutation """
    mutation SendEventPrivateMessageMutation(
      $text: String!
      $actorId: ID!
      $eventId: ID!
      $roles: [ParticipantRoleEnum]
      $language: String
    ) {
    sendEventPrivateMessage(
      text: $text
      actorId: $actorId
      eventId: $eventId
      roles: $roles
      language: $language
    ) {
      id
      conversationParticipantId
      actor {
        id
      }
      lastComment {
        id
        text
      }
      originComment {
        id
        text
      }
      participants {
        id
      }
      event {
        id
        uuid
        title
        organizerActor {
          id
        }
        attributedTo {
          id
        }
      }
      unread
      insertedAt
      updatedAt
      }
    }
    """

    setup %{conn: conn} do
      user = insert(:user)
      actor = insert(:actor, user: user, preferred_username: "test")

      {:ok, conn: conn, actor: actor, user: user}
    end

    test "Without being logged-in", %{conn: conn} do
      %Actor{id: actor_id} = insert(:actor)
      %Event{id: event_id} = insert(:event)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @send_event_private_message_mutation,
          variables: %{actorId: actor_id, eventId: event_id, text: "Hello dear participants"}
        )

      assert hd(res["errors"])["message"] == "You need to be logged in"
    end

    test "With actor not allowed", %{conn: conn, actor: actor, user: user} do
      %Event{id: event_id} = insert(:event)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @send_event_private_message_mutation,
          variables: %{actorId: actor.id, eventId: event_id, text: "Hello dear participants"}
        )

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
    end

    test "With actor as event organizer", %{conn: conn, actor: actor, user: user} do
      %Event{id: event_id, title: event_title, uuid: event_uuid} =
        event = insert(:event, organizer_actor: actor)

      %Participant{actor_id: participant_actor_id} = insert(:participant, event: event)
      %Participant{actor_id: participant_actor_id_2} = insert(:participant, event: event)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @send_event_private_message_mutation,
          variables: %{actorId: actor.id, eventId: event_id, text: "Hello dear participants"}
        )

      assert res["errors"] == nil

      assert res["data"]["sendEventPrivateMessage"]["lastComment"]["id"] ==
               res["data"]["sendEventPrivateMessage"]["originComment"]["id"]

      assert res["data"]["sendEventPrivateMessage"]["lastComment"]["text"] ==
               "Hello dear participants"

      participants_ids =
        Enum.map(res["data"]["sendEventPrivateMessage"]["participants"], fn participant ->
          String.to_integer(participant["id"])
        end)

      assert length(participants_ids) == 3

      assert MapSet.new(participants_ids) ==
               MapSet.new([actor.id, participant_actor_id, participant_actor_id_2])

      assert res["data"]["sendEventPrivateMessage"]["actor"]["id"] == to_string(actor.id)
      conversation_id = res["data"]["sendEventPrivateMessage"]["id"]

      all_conversation_participants_ids = Conversations.find_all_conversations_for_event(event_id)

      notified_conversation_participant_ids =
        all_conversation_participants_ids
        |> Enum.filter(&(&1.actor_id != actor.id))
        |> Enum.map(&[&1.id, &1.actor_id])

      Enum.each(notified_conversation_participant_ids, fn [pa_id, participant_actor_id] ->
        assert_enqueued(
          worker: LegacyNotifierBuilder,
          args: %{
            "author_id" => actor.id,
            "object_id" => to_string(conversation_id),
            "object_type" => "conversation",
            "op" => "legacy_notify",
            "subject" => "conversation_created",
            "subject_params" => %{
              "conversation_id" => String.to_integer(conversation_id),
              "conversation_participant_id" => pa_id,
              "conversation_text" => "Hello dear participants",
              "conversation_event_id" => event_id,
              "conversation_event_title" => event_title,
              "conversation_event_uuid" => event_uuid
            },
            "type" => "conversation",
            "participant" => %{
              "actor_id" => participant_actor_id,
              "id" => pa_id
            }
          }
        )
      end)

      ignored_conversation_participant_id =
        all_conversation_participants_ids
        |> Enum.filter(&(&1.actor_id == actor.id))
        |> Enum.map(& &1.id)

      refute_enqueued(
        worker: LegacyNotifierBuilder,
        args: %{
          "author_id" => actor.id,
          "object_id" => to_string(conversation_id),
          "object_type" => "conversation",
          "op" => "legacy_notify",
          "subject" => "conversation_created",
          "subject_params" => %{
            "conversation_id" => String.to_integer(conversation_id),
            "conversation_participant_id" => ignored_conversation_participant_id,
            "conversation_text" => "Hello dear participants",
            "conversation_event_id" => event_id,
            "conversation_event_title" => event_title,
            "conversation_event_uuid" => event_uuid
          },
          "type" => "conversation",
          "participant" => %{
            "actor_id" => actor.id,
            "id" => ignored_conversation_participant_id
          }
        }
      )
    end

    test "With actor as event organizer with customized roles", %{
      conn: conn,
      actor: actor,
      user: user
    } do
      %Event{id: event_id, title: event_title, uuid: event_uuid} =
        event = insert(:event, organizer_actor: actor)

      %Participant{actor_id: _participant_actor_id} = insert(:participant, event: event)

      %Participant{actor_id: participant_actor_id_2} =
        insert(:participant, event: event, role: :not_approved)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @send_event_private_message_mutation,
          variables: %{
            actorId: actor.id,
            eventId: event_id,
            text: "Hello dear participants",
            roles: ["NOT_APPROVED"]
          }
        )

      assert res["errors"] == nil

      assert res["data"]["sendEventPrivateMessage"]["lastComment"]["id"] ==
               res["data"]["sendEventPrivateMessage"]["originComment"]["id"]

      assert res["data"]["sendEventPrivateMessage"]["lastComment"]["text"] ==
               "Hello dear participants"

      participants_ids =
        Enum.map(res["data"]["sendEventPrivateMessage"]["participants"], fn participant ->
          String.to_integer(participant["id"])
        end)

      assert length(participants_ids) == 2

      assert MapSet.new(participants_ids) ==
               MapSet.new([actor.id, participant_actor_id_2])

      conversation_id = res["data"]["sendEventPrivateMessage"]["id"]

      all_conversation_participants_ids = Conversations.find_all_conversations_for_event(event_id)

      notified_conversation_participant_ids =
        all_conversation_participants_ids
        |> Enum.filter(&(&1.actor_id == participant_actor_id_2))
        |> Enum.map(&[&1.id, &1.actor_id])

      Enum.each(notified_conversation_participant_ids, fn [pa_id, participant_actor_id] ->
        assert_enqueued(
          worker: LegacyNotifierBuilder,
          args: %{
            "author_id" => actor.id,
            "object_id" => to_string(conversation_id),
            "object_type" => "conversation",
            "op" => "legacy_notify",
            "subject" => "conversation_created",
            "subject_params" => %{
              "conversation_id" => String.to_integer(conversation_id),
              "conversation_participant_id" => pa_id,
              "conversation_text" => "Hello dear participants",
              "conversation_event_id" => event_id,
              "conversation_event_title" => event_title,
              "conversation_event_uuid" => event_uuid
            },
            "type" => "conversation",
            "participant" => %{
              "actor_id" => participant_actor_id,
              "id" => pa_id
            }
          }
        )
      end)

      ignored_conversation_participant_id =
        all_conversation_participants_ids
        |> Enum.filter(&(&1.actor_id != participant_actor_id_2))
        |> Enum.map(&[&1.id, &1.actor_id])

      Enum.each(ignored_conversation_participant_id, fn [pa_id, participant_actor_id] ->
        refute_enqueued(
          worker: LegacyNotifierBuilder,
          args: %{
            "author_id" => participant_actor_id,
            "object_id" => to_string(conversation_id),
            "object_type" => "conversation",
            "op" => "legacy_notify",
            "subject" => "conversation_created",
            "subject_params" => %{
              "conversation_id" => String.to_integer(conversation_id),
              "conversation_participant_id" => pa_id,
              "conversation_text" => "Hello dear participants",
              "conversation_event_id" => event_id,
              "conversation_event_title" => event_title,
              "conversation_event_uuid" => event_uuid
            },
            "type" => "conversation",
            "participant" => %{
              "actor_id" => participant_actor_id,
              "id" => pa_id
            }
          }
        )
      end)
    end

    test "With actor as member of group event organizer", %{conn: conn, actor: actor, user: user} do
      %Actor{id: group_id} = group = insert(:group)
      insert(:member, parent: group, actor: actor, role: :moderator)
      %Event{id: event_id} = event = insert(:event, organizer_actor: actor, attributed_to: group)
      %Participant{actor_id: participant_actor_id} = insert(:participant, event: event)
      %Participant{actor_id: participant_actor_id_2} = insert(:participant, event: event)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @send_event_private_message_mutation,
          variables: %{actorId: group_id, eventId: event_id, text: "Hello dear participants"}
        )

      assert res["errors"] == nil

      participants_ids =
        Enum.map(res["data"]["sendEventPrivateMessage"]["participants"], fn participant ->
          String.to_integer(participant["id"])
        end)

      assert MapSet.new(participants_ids) ==
               MapSet.new([group_id, participant_actor_id, participant_actor_id_2])

      assert res["data"]["sendEventPrivateMessage"]["actor"]["id"] == to_string(group_id)
    end

    test "With event not found", %{conn: conn, actor: actor, user: user} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @send_event_private_message_mutation,
          variables: %{actorId: actor.id, eventId: "5019438457", text: "Hello dear participants"}
        )

      assert hd(res["errors"])["message"] ==
               "Event not found"
    end

    test "With no participants matching the audience", %{conn: conn, actor: actor, user: user} do
      %Event{id: event_id} = insert(:event, organizer_actor: actor)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @send_event_private_message_mutation,
          variables: %{actorId: actor.id, eventId: event_id, text: "Hello dear participants"}
        )

      assert hd(res["errors"])["message"] ==
               "There are no participants matching the audience you've selected."
    end
  end
end
