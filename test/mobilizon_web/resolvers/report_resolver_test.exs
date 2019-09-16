defmodule MobilizonWeb.Resolvers.ReportResolverTest do
  alias MobilizonWeb.AbsintheHelpers
  use MobilizonWeb.ConnCase
  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.{Report, Note}

  describe "Resolver: Report a content" do
    test "create_report/3 creates a report", %{conn: conn} do
      %User{} = user_reporter = insert(:user)
      %Actor{} = reporter = insert(:actor, user: user_reporter)
      %Actor{} = reported = insert(:actor)
      %Event{} = event = insert(:event, organizer_actor: reported)

      mutation = """
          mutation {
            createReport(
              reporter_actor_id: #{reporter.id},
              reported_actor_id: #{reported.id},
              event_id: #{event.id},
              report_content: "This is an issue"
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
        |> auth_conn(user_reporter)
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["createReport"]["content"] == "This is an issue"
      assert json_response(res, 200)["data"]["createReport"]["status"] == "OPEN"
      assert json_response(res, 200)["data"]["createReport"]["event"]["id"] == event.id
      assert json_response(res, 200)["data"]["createReport"]["reporter"]["id"] == reporter.id
    end

    test "create_report/3 without being connected doesn't create any report", %{conn: conn} do
      %Actor{} = reported = insert(:actor)

      mutation = """
          mutation {
            createReport(
              reported_actor_id: #{reported.id},
              reporter_actor_id: 5,
              report_content: "This is an issue"
            ) {
                content
              }
            }
      """

      res =
        conn
        |> post("/api", AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["errors"] |> hd |> Map.get("message") ==
               "You need to be logged-in to create reports"
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
               report.reporter.id
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

      %Report{id: report_1_id} = insert(:report)
      %Report{id: report_2_id} = insert(:report)
      %Report{id: report_3_id} = insert(:report)

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
        |> auth_conn(user_moderator)
        |> get("/api", AbsintheHelpers.query_skeleton(query, "report"))

      assert json_response(res, 200)["errors"] == nil

      assert json_response(res, 200)["data"]["reports"]
             |> Enum.map(fn report -> Map.get(report, "id") end)
             |> Enum.sort() ==
               [report_1_id, report_2_id, report_3_id]
               |> Enum.map(&to_string/1)
               |> Enum.sort()

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
      assert json_response(res, 200)["data"]["deleteReportNote"]["id"] == report_note_id
    end
  end
end
