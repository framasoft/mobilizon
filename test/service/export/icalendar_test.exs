defmodule Mobilizon.Service.ICalendarTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias ICalendar.Value

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Export.ICalendar, as: ICalendarService

  describe "export an event to ics" do
    test "export basic infos" do
      %Event{} = event = insert(:event)

      ics = """
      BEGIN:VCALENDAR
      CALSCALE:GREGORIAN
      VERSION:2.0
      PRODID:-//Elixir ICalendar//Mobilizon #{Mobilizon.Config.instance_version()}//EN
      BEGIN:VEVENT
      CATEGORIES:#{event.tags |> Enum.map(& &1.title) |> Enum.join(",")}
      DESCRIPTION:Ceci est une description avec une première phrase assez longue\\,\\n      puis sur une seconde ligne
      DTEND:#{Value.to_ics(event.ends_on)}Z
      DTSTAMP:#{Value.to_ics(event.publish_at)}Z
      DTSTART:#{Value.to_ics(event.begins_on)}Z
      GEO:#{event.physical_address |> Address.coords() |> Tuple.to_list() |> Enum.join(";")}
      LOCATION:#{Address.representation(event.physical_address)}
      SUMMARY:#{event.title}
      UID:#{event.uuid}
      URL:#{event.url}
      END:VEVENT
      END:VCALENDAR
      """

      assert {:ok, ics} == ICalendarService.export_public_event(event)
    end
  end
end
