defmodule Mobilizon.Service.Export.Participants.CSVTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Export.Participants.CSV

  describe "export event participants to csv" do
    test "export basic infos" do
      %Event{} = event = insert(:event)
      insert(:participant, event: event, role: :creator)
      insert(:participant, event: event, role: :participant)
      insert(:participant, event: event, role: :not_approved)

      assert CSV.ready?()
      assert {:ok, path} = CSV.export(event)
      assert content = File.read!("uploads/exports/csv/" <> path)
      assert content =~ "Participant name,Participant status,Participant message"
    end
  end
end
