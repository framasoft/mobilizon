defmodule Mobilizon.Export.ICalendar do
  @moduledoc """
  Export an event to iCalendar format
  """

  alias Mobilizon.Events.Event

  @spec export_event(%Event{}) :: String
  def export_event(%Event{} = event) do
    events = [
      %ICalendar.Event{
        summary: event.title,
        dtstart: event.begins_on,
        dtend: event.ends_on,
        description: event.description,
        uid: event.uuid
      }
    ]

    %ICalendar{events: events}
    |> ICalendar.to_ics()
  end
end
