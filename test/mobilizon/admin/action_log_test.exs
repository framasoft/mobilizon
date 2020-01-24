defmodule Mobilizon.Service.Admin.ActionLogTest do
  @moduledoc """
  Test the ActionLog module.
  """

  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Admin
  alias Mobilizon.Admin.ActionLog
  alias Mobilizon.Reports.{Note, Report}

  setup do
    moderator_user = insert(:user, role: :moderator)
    moderator_actor = insert(:actor, user: moderator_user)
    {:ok, moderator: moderator_actor}
  end

  describe "action_log_creation" do
    test "log a report update", %{moderator: moderator} do
      %Report{id: _report_id} = report = insert(:report)

      assert {:ok,
              %ActionLog{
                target_type: "Elixir.Mobilizon.Reports.Report",
                target_id: report_id,
                action: :update,
                actor: moderator
              }} = Admin.log_action(moderator, "update", report)
    end

    test "log the creation of a report note", %{moderator: moderator} do
      %Report{} = report = insert(:report)
      %Note{id: _note_id} = report = insert(:report_note, report: report)

      assert {:ok,
              %ActionLog{
                target_type: "Elixir.Mobilizon.Reports.Note",
                target_id: note_id,
                action: :create,
                actor: moderator
              }} = Admin.log_action(moderator, "create", report)
    end
  end
end
