defmodule Mobilizon.GraphQL.API.ReportTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Service.Formatter.HTML
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.API.Reports

  alias Mobilizon.Federation.ActivityPub.{Activity, Relay}

  describe "reports" do
    test "creates a report on a event" do
      %Actor{url: relay_reporter_url} = Relay.get_actor()
      %Actor{id: reporter_id} = insert(:actor)
      %Actor{id: reported_id, url: reported_url} = reported = insert(:actor)

      %Event{id: event_id, url: event_url} = _event = insert(:event, organizer_actor: reported)

      comment = "This is not acceptable"

      assert {:ok, %Activity{} = flag_activity, _} =
               Reports.report(%{
                 reporter_id: reporter_id,
                 reported_id: reported_id,
                 content: comment,
                 event_id: event_id,
                 comments_ids: [],
                 forward: false
               })

      assert %Activity{
               actor: ^relay_reporter_url,
               data: %{
                 "type" => "Flag",
                 "cc" => [],
                 "content" => ^comment,
                 "object" => [^reported_url, ^event_url]
               }
             } = flag_activity
    end

    test "creates a report on several comments" do
      %Actor{url: relay_reporter_url} = Relay.get_actor()
      %Actor{id: reporter_id} = insert(:actor)
      %Actor{id: reported_id, url: reported_url} = reported = insert(:actor)

      %Comment{id: comment_1_id, url: comment_1_url} =
        _comment_1 = insert(:comment, actor: reported)

      %Comment{id: comment_2_id, url: comment_2_url} =
        _comment_2 = insert(:comment, actor: reported)

      comment = "This is really not acceptable"

      assert {:ok, %Activity{} = flag_activity, _} =
               Reports.report(%{
                 reporter_id: reporter_id,
                 reported_id: reported_id,
                 content: comment,
                 event_id: nil,
                 comments_ids: [comment_1_id, comment_2_id]
               })

      assert %Activity{
               actor: ^relay_reporter_url,
               data: %{
                 "type" => "Flag",
                 "content" => ^comment,
                 "object" => [^reported_url, ^comment_1_url, ^comment_2_url],
                 "to" => [],
                 "cc" => [],
                 "actor" => ^relay_reporter_url
               }
             } = flag_activity
    end

    test "creates a report that gets federated" do
      %Actor{url: relay_reporter_url} = Relay.get_actor()
      %Actor{id: reporter_id} = insert(:actor)
      %Actor{id: reported_id, url: reported_url} = reported = insert(:actor)

      %Comment{id: comment_1_id, url: comment_1_url} =
        _comment_1 = insert(:comment, actor: reported)

      %Comment{id: comment_2_id, url: comment_2_url} =
        _comment_2 = insert(:comment, actor: reported)

      comment = "This is really not acceptable, remote admin I don't know"
      encoded_comment = HTML.strip_tags(comment)

      assert {:ok, %Activity{} = flag_activity, _} =
               Reports.report(%{
                 reporter_id: reporter_id,
                 reported_id: reported_id,
                 content: comment,
                 event_id: nil,
                 comments_ids: [comment_1_id, comment_2_id],
                 forward: true
               })

      assert %Activity{
               actor: ^relay_reporter_url,
               data: %{
                 "type" => "Flag",
                 "actor" => ^relay_reporter_url,
                 "cc" => [^reported_url],
                 "content" => ^encoded_comment,
                 "object" => [^reported_url, ^comment_1_url, ^comment_2_url],
                 "to" => []
               },
               local: true,
               recipients: [^reported_url]
             } = flag_activity
    end

    test "updates report state" do
      %Actor{id: reporter_id} = insert(:actor)
      %Actor{id: reported_id} = reported = insert(:actor)

      %Comment{id: comment_1_id} = _comment_1 = insert(:comment, actor: reported)

      assert {:ok, %Activity{} = flag_activity, %Report{id: report_id} = _report} =
               Reports.report(%{
                 reporter_id: reporter_id,
                 reported_id: reported_id,
                 content: "This is not a nice thing",
                 event_id: nil,
                 comments_ids: [comment_1_id],
                 forward: true
               })

      %Report{} = report = Mobilizon.Reports.get_report(report_id)

      %User{} = manager_user = insert(:user, role: :moderator)
      %Actor{} = manager_actor = insert(:actor, user: manager_user)

      {:ok, new_report} = Reports.update_report_status(manager_actor, report, :resolved)

      assert new_report.status == :resolved
    end

    test "updates report state with not acceptable status" do
      %Actor{id: reporter_id} = insert(:actor)
      %Actor{id: reported_id} = reported = insert(:actor)

      %Comment{id: comment_1_id} = _comment_1 = insert(:comment, actor: reported)

      assert {:ok, %Activity{} = flag_activity, %Report{id: report_id} = _report} =
               Reports.report(%{
                 reporter_id: reporter_id,
                 reported_id: reported_id,
                 content: "This is not a nice thing",
                 event_id: nil,
                 comments_ids: [comment_1_id],
                 forward: true
               })

      %Report{} = report = Mobilizon.Reports.get_report(report_id)

      %Actor{} = manager_actor = insert(:actor)

      {:error, "Unsupported state"} = Reports.update_report_status(manager_actor, report, :test)
    end
  end

  describe "note reports" do
    test "creates a note on a report" do
      %User{} = moderator_user = insert(:user, role: :moderator)
      %Actor{} = moderator_actor = insert(:actor, user: moderator_user)
      %Report{} = report = insert(:report)

      assert {:ok, %Note{} = _note} =
               Reports.create_report_note(
                 report,
                 moderator_actor,
                 "I'll take care of this later today"
               )
    end

    test "doesn't create a note on a report when not moderator" do
      %User{} = user = insert(:user)
      %Actor{} = actor = insert(:actor, user: user)
      %Report{} = report = insert(:report)

      assert {:error,
              "You need to be a moderator or an administrator to create a note on a report"} =
               Reports.create_report_note(report, actor, "I'll take care of this later today")
    end

    test "deletes a note on a report" do
      %User{} = moderator_user = insert(:user, role: :moderator)
      %Actor{} = moderator_actor = insert(:actor, user: moderator_user)
      %Note{} = note = insert(:report_note, moderator: moderator_actor)
      assert {:ok, %Note{}} = Reports.delete_report_note(note, moderator_actor)
    end

    test "deletes a note on a report with a different moderator actor" do
      %Note{} = note = insert(:report_note)

      %User{} = other_moderator_user = insert(:user, role: :moderator)
      %Actor{} = other_moderator_actor = insert(:actor, user: other_moderator_user)

      assert {:error, "You can only remove your own notes"} =
               Reports.delete_report_note(note, other_moderator_actor)
    end

    test "try deletes a note on a report with a actor not moderator anymore" do
      %User{} = moderator_user = insert(:user, role: :moderator)
      %Actor{} = moderator_actor = insert(:actor, user: moderator_user)
      %Note{} = note = insert(:report_note, moderator: moderator_actor)

      Users.update_user(moderator_user, %{role: :user})

      assert {:error,
              "You need to be a moderator or an administrator to create a note on a report"} =
               Reports.delete_report_note(note, moderator_actor)
    end
  end
end
