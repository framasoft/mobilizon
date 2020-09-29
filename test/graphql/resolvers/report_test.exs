defmodule Mobilizon.GraphQL.Resolvers.ReportTest do
  use Mobilizon.Web.ConnCase
  use Mobilizon.Tests.Helpers

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.AbsintheHelpers

  describe "Resolver: Report a content" do
    @create_report_mutation """
    mutation CreateReport($reporterId: ID!, $reportedId: ID!, $eventId: ID, $content: String) {
      createReport(
        reporterId: $reporterId,
        reportedId: $reportedId,
        eventId: $eventId,
        content: $content
      ) {
          content,
          reporter {
            id
          },
          event {
            id
          },
          status
        }
      }
    """

    setup do: clear_config([:anonymous, :reports])

    setup %{conn: conn} do
      Mobilizon.Config.clear_config_cache()
      anonymous_actor_id = Config.anonymous_actor_id()
      {:ok, conn: conn, anonymous_actor_id: anonymous_actor_id}
    end

    test "create_report/3 creates a report", %{conn: conn} do
      %User{} = user_reporter = insert(:user)
      %Actor{} = reporter = insert(:actor, user: user_reporter)
      %Actor{} = reported = insert(:actor)
      %Event{} = event = insert(:event, organizer_actor: reported)

      res =
        conn
        |> auth_conn(user_reporter)
        |> AbsintheHelpers.graphql_query(
          query: @create_report_mutation,
          variables: %{
            reportedId: reported.id,
            reporterId: reporter.id,
            eventId: event.id,
            content: "This is an issue"
          }
        )

      assert res["errors"] == nil
      assert res["data"]["createReport"]["content"] == "This is an issue"
      assert res["data"]["createReport"]["status"] == "OPEN"
      assert res["data"]["createReport"]["event"]["id"] == to_string(event.id)

      assert res["data"]["createReport"]["reporter"]["id"] ==
               to_string(reporter.id)
    end

    test "create_report/3 without being connected doesn't create any report", %{conn: conn} do
      %Actor{} = reported = insert(:actor)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_report_mutation,
          variables: %{
            reportedId: reported.id,
            reporterId: 5,
            content: "This is an issue"
          }
        )

      assert res["errors"] |> hd |> Map.get("message") ==
               "You need to be logged-in to create reports"
    end

    test "create_report/3 anonymously creates a report if config has allowed", %{
      conn: conn,
      anonymous_actor_id: anonymous_actor_id
    } do
      %Actor{} = reported = insert(:actor)
      Config.put([:anonymous, :reports, :allowed], true)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_report_mutation,
          variables: %{
            reportedId: reported.id,
            reporterId: anonymous_actor_id,
            content: "This is an issue"
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["createReport"]["content"] == "This is an issue"
      assert res["data"]["createReport"]["status"] == "OPEN"

      assert res["data"]["createReport"]["reporter"]["id"] ==
               to_string(anonymous_actor_id)
    end

    test "create_report/3 anonymously doesn't creates a report if the anonymous actor ID is wrong",
         %{conn: conn} do
      %Actor{} = reported = insert(:actor)
      Config.put([:anonymous, :reports, :allowed], true)

      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @create_report_mutation,
          variables: %{
            reportedId: reported.id,
            reporterId: 53,
            content: "This is an issue"
          }
        )

      assert res["errors"] |> hd |> Map.get("message") ==
               "Reporter ID does not match the anonymous profile id"
    end
  end

  describe "Resolver: update a report" do
    test "update_report/3 updates the report's status", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %Actor{} = moderator = insert(:actor, user: user_moderator)
      %Report{} = report = insert(:report)

      mutation = """
          mutation {
            updateReportStatus(
              report_id: #{report.id},
              moderator_id: #{moderator.id},
              status: RESOLVED
            ) {
                content,
                reporter {
                  id
                },
                event {
                  id
                },
                status
              }
            }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["updateReportStatus"]["content"] ==
               "This is problematic"

      assert json_response(res, 200)["data"]["updateReportStatus"]["status"] == "RESOLVED"

      assert json_response(res, 200)["data"]["updateReportStatus"]["reporter"]["id"] ==
               to_string(report.reporter.id)
    end

    test "create_report/3 without being connected doesn't create any report", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %Actor{} = moderator = insert(:actor, user: user_moderator)
      %Report{} = report = insert(:report)

      mutation = """
          mutation {
            updateReportStatus(
              report_id: #{report.id},
              moderator_id: #{moderator.id},
              status: RESOLVED
            ) {
                content
              }
            }
      """

      res =
        conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
               "You need to be logged-in and a moderator to update a report"
    end
  end

  describe "Resolver: Get list of reports" do
    test "get an empty list of reports", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)

      query = """
      {
        reports {
          id,
          reported {
            preferredUsername
          }
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "report"))

      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
               "You need to be logged-in and a moderator to list reports"

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "report"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["reports"] == []
    end

    test "get a list of reports", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)

      # Report don't hold millisecond information so we need to wait a bit
      # between each insert to keep order
      %Report{id: report_1_id} = insert(:report, content: "My content 1")
      Process.sleep(1000)
      %Report{id: report_2_id} = insert(:report, content: "My content 2")
      Process.sleep(1000)
      %Report{id: report_3_id} = insert(:report, content: "My content 3")
      %Report{} = insert(:report, status: :closed)

      query = """
      {
        reports {
          id,
          reported {
            preferredUsername
          },
          content,
          updatedAt
        }
      }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "report"))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["reports"]
             |> Enum.map(fn report -> Map.get(report, "id") end) ==
               Enum.map([report_3_id, report_2_id, report_1_id], &to_string/1)

      query = """
      {
        reports(page: 2, limit: 2) {
          id,
          reported {
            preferredUsername
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "report"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["reports"] |> length == 1

      query = """
      {
        reports(page: 3, limit: 2) {
          id,
          reported {
            preferredUsername
          }
        }
      }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "report"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["reports"] |> length == 0
    end
  end

  describe "Resolver: View a report" do
    test "view a report", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %Actor{} = insert(:actor, user: user_moderator)
      %Actor{} = reporter = insert(:actor)
      %Report{} = report = insert(:report, reporter: reporter)

      query = """
      {
        report (id: "#{report.id}") {
          id,
          reported {
            preferredUsername
          },
          reporter {
            preferredUsername
          },
          event {
            title
          },
          comments {
            text
          },
          content
        }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "report"))

      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
               "You need to be logged-in and a moderator to view a report"

      res =
        conn
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "report"))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["report"]["reported"]["preferredUsername"] ==
               report.reported.preferred_username

      assert json_response(res, 200)["data"]["report"]["reporter"]["preferredUsername"] ==
               reporter.preferred_username

      assert json_response(res, 200)["data"]["report"]["content"] == report.content
      assert json_response(res, 200)["data"]["report"]["event"]["title"] == report.event.title

      assert json_response(res, 200)["data"]["report"]["comments"] |> hd |> Map.get("text") ==
               report.comments |> hd |> Map.get(:text)
    end
  end

  describe "Resolver: Add a note on a report" do
    @report_note_content "I agree with this this report"

    test "create_report_note/3 creates a report note", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %Actor{id: moderator_id} = moderator = insert(:actor, user: user_moderator)
      %Report{id: report_id} = insert(:report)

      mutation = """
          mutation {
            createReportNote(
              moderator_id: #{moderator_id},
              report_id: #{report_id},
              content: "#{@report_note_content}"
            ) {
                content,
                moderator {
                  preferred_username
                },
                report {
                  id
                }
              }
            }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["createReportNote"]["content"] ==
               @report_note_content

      assert json_response(res, 200)["data"]["createReportNote"]["moderator"][
               "preferred_username"
             ] == moderator.preferred_username

      assert json_response(res, 200)["data"]["createReportNote"]["report"]["id"] ==
               to_string(report_id)
    end

    test "delete_report_note deletes a report note", %{conn: conn} do
      %User{} = user_moderator = insert(:user, role: :moderator)
      %Actor{id: moderator_id} = moderator = insert(:actor, user: user_moderator)
      %Note{id: report_note_id} = insert(:report_note, moderator: moderator)

      mutation = """
          mutation {
            deleteReportNote(
              moderator_id: #{moderator_id},
              note_id: #{report_note_id},
            ) {
                id
              }
            }
      """

      res =
        conn
        |> auth_conn(user_moderator)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["deleteReportNote"]["id"] ==
               to_string(report_note_id)
    end
  end
end
