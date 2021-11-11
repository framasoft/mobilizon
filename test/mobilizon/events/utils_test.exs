defmodule Mobilizon.Events.UtilsTest do
  use Mobilizon.DataCase, async: true

  alias Mobilizon.Events.Utils

  @now ~U[2021-11-19T18:17:00Z]

  describe "calculate_notification_time" do
    test "when the event begins in less than 30 minutes" do
      begins_on = ~U[2021-11-19T18:27:00Z]
      assert @now == Utils.calculate_notification_time(begins_on, now: @now)
    end

    test "when the event begins in more than 30 minutes" do
      begins_on = ~U[2021-11-19T18:17:00Z]
      assert begins_on == Utils.calculate_notification_time(begins_on, now: @now)
    end
  end
end
