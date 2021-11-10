defmodule Mobilizon.Events.Utils do
  @moduledoc """
  Utils related to events
  """

  @spec calculate_notification_time(DateTime.t()) :: DateTime.t()
  def calculate_notification_time(begins_on, options \\ []) do
    now = Keyword.get(options, :now, DateTime.utc_now())
    notify_at = DateTime.add(now, 1800)

    # If the event begins in less than half an hour, send the notification right now
    if DateTime.compare(notify_at, begins_on) == :lt do
      notify_at
    else
      now
    end
  end
end
