defmodule Mobilizon.Federation.ActivityPub.Types.ReportsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Types.Reports
  alias Mobilizon.Reports.Report

  describe "report creation" do
    test "with XSS" do
      %Actor{id: reporter_id} = insert(:actor)
      %Actor{id: reported_id} = insert(:actor)

      content =
        "hello <meta http-equiv=\"refresh\" content=\"0; url=http://example.com/\" />"

      assert {:ok, %Report{content: saved_content}, _} =
               Reports.flag(%{
                 reporter_id: reporter_id,
                 reported_id: reported_id,
                 content: content
               })

      assert saved_content == "hello "

      content =
        "<<img src=''/>meta http-equiv=\"refresh\" content=\"0; url=http://example.com/\" />"

      assert {:ok, %Report{content: saved_content}, _} =
               Reports.flag(%{
                 reporter_id: reporter_id,
                 reported_id: reported_id,
                 content: content
               })

      assert saved_content ==
               "<meta http-equiv=\"refresh\" content=\"0; url=http://example.com/\" />"
    end
  end
end
