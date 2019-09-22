defmodule MobilizonWeb.Resolvers.AdminResolverTest do
  use MobilizonWeb.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Users.User

  alias MobilizonWeb.AbsintheHelpers

  describe "Resolver: List the action logs" do
    @note_content "This a note on a report"
    test "list_action_logs/3 list action logs", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %Actor{} = moderator = insert(:actor, user: user_moderator)

      %User{} = user_moderator_2 = insert(:user, role: :moderator)
      %Actor{} = moderator_2 = insert(:actor, user: user_moderator_2)

      %Report{} = report = insert(:report)
      MobilizonWeb.API.Reports.update_report_status(moderator, report, "resolved")

      {:ok, %Note{} = note} =
        MobilizonWeb.API.Reports.create_report_note(report, moderator_2, @note_content)

      MobilizonWeb.API.Reports.delete_report_note(note, moderator_2)

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
end
