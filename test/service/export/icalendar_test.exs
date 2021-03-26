defmodule Mobilizon.Service.ICalendarTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias ICalendar.Value

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.{Event, FeedToken}
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

  describe "export the instance's public events" do
    test "succeds" do
      %Event{} = event = insert(:event, title: "I'm public")
      %Event{} = event2 = insert(:event, visibility: :private, title: "I'm private")
      %Event{} = event3 = insert(:event, title: "Another public")

      {:commit, ics} = ICalendarService.create_cache("instance")
      assert ics =~ event.title
      refute ics =~ event2.title
      assert ics =~ event3.title
    end
  end

  describe "export an actor's events from a token" do
    test "an actor feedtoken" do
      user = insert(:user)
      actor = insert(:actor, user: user)
      %FeedToken{token: token} = insert(:feed_token, user: user, actor: actor)
      event = insert(:event)
      insert(:participant, event: event, actor: actor, role: :participant)

      {:commit, ics} = ICalendarService.create_cache("token_#{ShortUUID.encode!(token)}")
      assert ics =~ event.title
    end
  end
end
