defmodule Mobilizon.Service.Export.Participants.ODSTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Export.Participants.ODS

  setup do
    test_format?()
  end

  describe "export event participants to ods" do
    test "export basic infos" do
      %Event{} = event = insert(:event)
      insert(:participant, event: event, role: :creator)
      insert(:participant, event: event, role: :participant)
      insert(:participant, event: event, role: :not_approved)

      set_exports(Mobilizon.Service.Export.Participants.CSV)

      refute ODS.ready?()
    end

    test "enable the exporter" do
      set_exports(Mobilizon.Service.Export.Participants.ODS)

      %Event{} = event = insert(:event)
      insert(:participant, event: event, role: :creator)
      insert(:participant, event: event, role: :participant)
      insert(:participant, event: event, role: :not_approved)

      assert ODS.dependencies_ok?()
      assert ODS.enabled?()
      assert {:ok, path} = ODS.export(event)
      assert File.exists?("uploads/exports/ods/" <> path)
      set_exports(Mobilizon.Service.Export.Participants.CSV)
    end
  end

  @spec set_exports(module()) :: :ok
  defp set_exports(module) do
    Mobilizon.Config.put(:exports,
      formats: [module]
    )
  end

  @spec test_format? :: :ok | {:ok, skip: true}
  defp test_format? do
    case System.get_env("EXPORT_FORMATS") do
      nil ->
        {:ok, skip: true}

      formats ->
        if "ods" in String.split(formats, ",") do
          :ok
        else
          {:ok, skip: true}
        end
    end
  end
end
