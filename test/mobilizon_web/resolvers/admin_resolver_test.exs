defmodule MobilizonWeb.Resolvers.AdminResolverTest do
  use MobilizonWeb.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Users.User

  alias MobilizonWeb.AbsintheHelpers
  alias MobilizonWeb.API

  describe "Resolver: List the action logs" do
    @note_content "This a note on a report"
    test "list_action_logs/3 list action logs", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %Actor{} = moderator = insert(:actor, user: user_moderator)

      %User{} = user_moderator_2 = insert(:user, role: :moderator)
      %Actor{} = moderator_2 = insert(:actor, user: user_moderator_2)

      %Report{} = report = insert(:report)
      API.Reports.update_report_status(moderator, report, "resolved")

      {:ok, %Note{} = note} = API.Reports.create_report_note(report, moderator_2, @note_content)

      API.Reports.delete_report_note(note, moderator_2)

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
          }
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
               "You need to be logged-in and a moderator to list action logs"

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["actionLogs"] |> length == 3

      assert json_response(res, 200)["data"]["actionLogs"] == [
               %{
                 "action" => "NOTE_DELETION",
                 "actor" => %{"preferredUsername" => moderator_2.preferred_username},
                 "object" => %{"content" => @note_content}
               },
               %{
                 "action" => "NOTE_CREATION",
                 "actor" => %{"preferredUsername" => moderator_2.preferred_username},
                 "object" => %{"content" => @note_content}
               },
               %{
                 "action" => "REPORT_UPDATE_RESOLVED",
                 "actor" => %{"preferredUsername" => moderator.preferred_username},
                 "object" => %{"id" => to_string(report.id), "status" => "RESOLVED"}
               }
             ]
    end
  end

  describe "Resolver: Get the dashboard statistics" do
    test "get_dashboard/3 gets dashboard information", %{conn: conn} do
      %Event{title: title} = insert(:event)

      %User{} = user_admin = insert(:user, role: :administrator)

      query = """
      {
        dashboard {
          lastPublicEventPublished {
            title
          }
          numberOfUsers,
          numberOfComments,
          numberOfEvents,
          numberOfReports
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
               "You need to be logged-in and an administrator to access dashboard statistics"

      res =
        conn
        |> auth_conn(user_admin)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "actionLogs"))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["dashboard"]["lastPublicEventPublished"]["title"] ==
               title
    end
  end

  describe "Resolver: Get the list of relay followers" do
    test "test list_relay_followers/3 returns relay followers", %{conn: conn} do
      %User{} = user_admin = insert(:user, role: :administrator)

      follower_actor =
        insert(:actor,
          domain: "localhost",
          user: nil,
          url: "http://localhost:8080/actor",
          preferred_username: "instance_actor",
          name: "I am an instance actor"
        )

      %Actor{} = relay_actor = Mobilizon.Service.ActivityPub.Relay.get_actor()
      insert(:follower, actor: follower_actor, target_actor: relay_actor)

      query = """
      {
        relayFollowers {
          elements {
            actor {
              preferredUsername,
              domain,
            },
            approved
          },
          total
        }
      }
      """

      res =
        conn
        |> auth_conn(user_admin)
        |> AbsintheHelpers.graphql_query(query: query)

      assert is_nil(res["errors"])

      assert hd(res["data"]["relayFollowers"]["elements"]) == %{
               "actor" => %{"preferredUsername" => "instance_actor", "domain" => "localhost"},
               "approved" => false
             }
    end

    test "test list_relay_followers/3 returns relay followings", %{conn: conn} do
      %User{} = user_admin = insert(:user, role: :administrator)

      %Actor{
        preferred_username: following_actor_preferred_username,
        domain: following_actor_domain
      } =
        following_actor =
        insert(:actor,
          domain: "localhost",
          user: nil,
          url: "http://localhost:8080/actor",
          preferred_username: "instance_actor",
          name: "I am an instance actor"
        )

      %Actor{} = relay_actor = Mobilizon.Service.ActivityPub.Relay.get_actor()
      insert(:follower, actor: relay_actor, target_actor: following_actor)

      query = """
      {
        relayFollowings {
          elements {
            targetActor {
              preferredUsername,
              domain,
            },
            approved
          },
          total
        }
      }
      """

      res =
        conn
        |> auth_conn(user_admin)
        |> AbsintheHelpers.graphql_query(query: query)

      assert is_nil(res["errors"])

      assert hd(res["data"]["relayFollowings"]["elements"]) == %{
               "targetActor" => %{
                 "preferredUsername" => following_actor_preferred_username,
                 "domain" => following_actor_domain
               },
               "approved" => false
             }
    end
  end
end
