defmodule Mobilizon.Service.ErrorReportingTest do
  @moduledoc """
  Mpdule to test loading and configuring error reporting adapters
  """

  use ExUnit.Case, async: true
  import Mox
  alias Mobilizon.Service.ErrorReporting

  defmock(ErrorReportingMock, for: ErrorReporting)

  describe "adapter/0 returns the enabled adapter" do
    test "adapter/0 returns the configured adapter if enabled" do
      expect(ErrorReportingMock, :enabled?, fn ->
        true
      end)

      Mobilizon.Config.put([Mobilizon.Service.ErrorReporting, :adapter], ErrorReportingMock)

      assert ErrorReportingMock == ErrorReporting.adapter()
    end

    test "adapter/0 returns nothing if configured adapter is not enabled" do
      expect(ErrorReportingMock, :enabled?, fn ->
        false
      end)

      Mobilizon.Config.put([Mobilizon.Service.ErrorReporting, :adapter], ErrorReportingMock)

      assert nil == ErrorReporting.adapter()
    end

    test "adapter/0 returns nothing if not adapter is configured adapter is configured" do
      expect(ErrorReportingMock, :enabled?, fn ->
        true
      end)

      Mobilizon.Config.put([Mobilizon.Service.ErrorReporting, :adapter], nil)

      assert nil == ErrorReporting.adapter()
    end
  end

  describe "forwards to the configured adapter the method" do
    setup do
      expect(ErrorReportingMock, :enabled?, fn ->
        true
      end)

      Mobilizon.Config.put([Mobilizon.Service.ErrorReporting, :adapter], ErrorReportingMock)

      :ok
    end

    test "attach/0" do
      expect(ErrorReportingMock, :attach, fn ->
        :attached
      end)

      assert :attached == ErrorReporting.attach()
    end

    test "handle_event/4" do
      expect(ErrorReportingMock, :handle_event, fn arg1, arg2, arg3, arg4 ->
        {:handled_event, [arg1, arg2, arg3, arg4]}
      end)

      assert {:handled_event, [:one, :two, :three, :four]} ==
               ErrorReporting.handle_event(:one, :two, :three, :four)
    end

    test "configure/0" do
      expect(ErrorReportingMock, :configure, fn ->
        :configured
      end)

      assert :configured == ErrorReporting.configure()
    end
  end
end
