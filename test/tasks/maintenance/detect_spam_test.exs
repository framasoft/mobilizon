defmodule Mix.Tasks.Mobilizon.Maintenance.DetectSpamTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mix.Tasks.Mobilizon.Maintenance.DetectSpam

  Mix.shell(Mix.Shell.Process)

  describe "detect spam" do
    @tag :skip
    test "on all content" do
      insert(:actor, preferred_username: "ham")
      insert(:actor, preferred_username: "spam")
      insert(:event, description: "some ham event", title: "some ham event")
      spam_event = insert(:event, description: "some spam event", title: "some spam event")

      DetectSpam.run(["-v"])
      assert_received {:mix_shell, :info, [output_received]}
      assert_received {:mix_shell, :info, [output_received2]}
      assert_received {:mix_shell, :info, [output_received3]}
      assert_received {:mix_shell, :info, [output_received4]}
      assert_received {:mix_shell, :info, [output_received5]}
      assert_received {:mix_shell, :info, [output_received6]}
      assert_received {:mix_shell, :info, [output_received7]}
      assert_received {:mix_shell, :info, [output_received8]}
      assert_received {:mix_shell, :info, [output_received9]}
      assert_received {:mix_shell, :info, [output_received10]}
      assert_received {:mix_shell, :info, [output_received11]}
      assert_received {:mix_shell, :info, [output_received12]}

      output =
        MapSet.new([
          output_received,
          output_received2,
          output_received3,
          output_received4,
          output_received5,
          output_received6,
          output_received7,
          output_received8,
          output_received9,
          output_received10,
          output_received11,
          output_received12
        ])

      assert MapSet.member?(output, "Starting scanning of profiles")
      assert MapSet.member?(output, "Starting scanning of events")
      assert MapSet.member?(output, "Profile ham is fine")
      assert MapSet.member?(output, "Event some ham event is fine")
      assert MapSet.member?(output, "Detected profile spam as spam")
      assert MapSet.member?(output, "Detected event some spam event as spam: #{spam_event.url}")
    end
  end
end
