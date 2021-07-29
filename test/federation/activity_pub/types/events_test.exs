defmodule Mobilizon.Federation.ActivityPub.Types.EventsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.Types.Events

  @ap_public "https://www.w3.org/ns/activitystreams#Public"

  describe "test event creation" do
    @event_begins_on "2021-07-28T15:04:22Z"
    @event_title "hey"
    @event_data %{title: @event_title, begins_on: @event_begins_on}

    test "from a simple profile" do
      %Actor{id: organizer_actor_id, url: actor_url, followers_url: followers_url} =
        insert(:actor)

      assert {:ok, %Event{}, data} =
               Events.create(
                 Map.merge(@event_data, %{organizer_actor_id: organizer_actor_id}),
                 %{}
               )

      assert match?(
               %{
                 "actor" => ^actor_url,
                 "attributedTo" => ^actor_url,
                 "cc" => [^followers_url],
                 "object" => %{
                   "actor" => ^actor_url,
                   "anonymousParticipationEnabled" => false,
                   "attachment" => [],
                   "attributedTo" => ^actor_url,
                   "category" => nil,
                   "cc" => [],
                   "commentsEnabled" => false,
                   "content" => nil,
                   "draft" => false,
                   "endTime" => nil,
                   "ical:status" => "CONFIRMED",
                   "joinMode" => "free",
                   "maximumAttendeeCapacity" => nil,
                   "mediaType" => "text/html",
                   "name" => @event_title,
                   "repliesModerationOption" => nil,
                   "startTime" => @event_begins_on,
                   "tag" => [],
                   "to" => [@ap_public],
                   "type" => "Event"
                 },
                 "to" => [@ap_public],
                 "type" => "Create"
               },
               data
             )
    end

    test "an unlisted event" do
      %Actor{id: organizer_actor_id, url: actor_url, followers_url: followers_url} =
        insert(:actor)

      assert {:ok, %Event{}, data} =
               Events.create(
                 Map.merge(@event_data, %{
                   organizer_actor_id: organizer_actor_id,
                   visibility: :unlisted
                 }),
                 %{}
               )

      assert match?(
               %{
                 "actor" => ^actor_url,
                 "attributedTo" => ^actor_url,
                 "cc" => [@ap_public],
                 "object" => %{
                   "actor" => ^actor_url,
                   "anonymousParticipationEnabled" => false,
                   "attachment" => [],
                   "attributedTo" => ^actor_url,
                   "category" => nil,
                   "cc" => [@ap_public],
                   "commentsEnabled" => false,
                   "content" => nil,
                   "draft" => false,
                   "endTime" => nil,
                   "ical:status" => "CONFIRMED",
                   "joinMode" => "free",
                   "maximumAttendeeCapacity" => nil,
                   "mediaType" => "text/html",
                   "name" => @event_title,
                   "repliesModerationOption" => nil,
                   "startTime" => @event_begins_on,
                   "tag" => [],
                   "to" => [^followers_url],
                   "type" => "Event"
                 },
                 "to" => [^followers_url],
                 "type" => "Create"
               },
               data
             )
    end

    test "from a group member" do
      %Actor{id: organizer_actor_id, url: actor_url} = actor = insert(:actor)

      %Actor{
        id: attributed_to_id,
        url: group_url,
        followers_url: followers_url,
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      insert(:member, parent: group, actor: actor, role: :moderator)

      assert {:ok, %Event{}, data} =
               Events.create(
                 Map.merge(@event_data, %{
                   organizer_actor_id: organizer_actor_id,
                   attributed_to_id: attributed_to_id
                 }),
                 %{}
               )

      assert match?(
               %{
                 "actor" => ^actor_url,
                 "attributedTo" => ^group_url,
                 "cc" => [^members_url, ^followers_url],
                 "object" => %{
                   "actor" => ^actor_url,
                   "anonymousParticipationEnabled" => false,
                   "attachment" => [],
                   "attributedTo" => ^group_url,
                   "category" => nil,
                   "cc" => [],
                   "commentsEnabled" => false,
                   "content" => nil,
                   "draft" => false,
                   "endTime" => nil,
                   "ical:status" => "CONFIRMED",
                   "joinMode" => "free",
                   "maximumAttendeeCapacity" => nil,
                   "mediaType" => "text/html",
                   "name" => @event_title,
                   "repliesModerationOption" => nil,
                   "startTime" => @event_begins_on,
                   "tag" => [],
                   "to" => [@ap_public],
                   "type" => "Event"
                 },
                 "to" => [@ap_public],
                 "type" => "Create"
               },
               data
             )
    end
  end

  @event_updated_title "my event updated"
  @event_update_data %{title: @event_updated_title}

  describe "test event update" do
    test "from a simple profile" do
      %Actor{url: actor_url, followers_url: followers_url} = actor = insert(:actor)

      {:ok, begins_on, _} = DateTime.from_iso8601(@event_begins_on)
      %Event{} = event = insert(:event, organizer_actor: actor, begins_on: begins_on)

      assert {:ok, %Event{}, data} =
               Events.update(
                 event,
                 @event_update_data,
                 %{}
               )

      assert match?(
               %{
                 "actor" => ^actor_url,
                 "attributedTo" => ^actor_url,
                 "cc" => [^followers_url],
                 "object" => %{
                   "actor" => ^actor_url,
                   "anonymousParticipationEnabled" => false,
                   "attributedTo" => ^actor_url,
                   "cc" => [],
                   "commentsEnabled" => false,
                   "draft" => false,
                   "ical:status" => "CONFIRMED",
                   "joinMode" => "free",
                   "maximumAttendeeCapacity" => nil,
                   "mediaType" => "text/html",
                   "name" => @event_updated_title,
                   "repliesModerationOption" => nil,
                   "startTime" => @event_begins_on,
                   "tag" => [],
                   "to" => [@ap_public],
                   "type" => "Event"
                 },
                 "to" => [@ap_public],
                 "type" => "Update"
               },
               data
             )
    end

    test "from a group member" do
      %Actor{} = actor_1 = insert(:actor)
      %Actor{id: organizer_actor_2_id, url: actor_2_url} = actor_2 = insert(:actor)

      %Actor{
        url: group_url,
        followers_url: followers_url,
        members_url: members_url
      } = group = insert(:group, domain: "somewhere.else", url: "https://somewhere.else/@someone")

      insert(:member, parent: group, actor: actor_1, role: :moderator)
      insert(:member, parent: group, actor: actor_2, role: :moderator)

      {:ok, begins_on, _} = DateTime.from_iso8601(@event_begins_on)

      %Event{} =
        event =
        insert(:event, organizer_actor: actor_1, begins_on: begins_on, attributed_to: group)

      assert {:ok, %Event{}, data} =
               Events.update(
                 event,
                 Map.merge(@event_update_data, %{
                   organizer_actor_id: organizer_actor_2_id
                 }),
                 %{}
               )

      assert match?(
               %{
                 "actor" => ^actor_2_url,
                 "attributedTo" => ^group_url,
                 "cc" => [^members_url, ^followers_url],
                 "object" => %{
                   "actor" => ^actor_2_url,
                   "anonymousParticipationEnabled" => false,
                   "attributedTo" => ^group_url,
                   "cc" => [],
                   "commentsEnabled" => false,
                   "draft" => false,
                   "ical:status" => "CONFIRMED",
                   "joinMode" => "free",
                   "maximumAttendeeCapacity" => nil,
                   "mediaType" => "text/html",
                   "name" => @event_updated_title,
                   "repliesModerationOption" => nil,
                   "startTime" => @event_begins_on,
                   "tag" => [],
                   "to" => [@ap_public],
                   "type" => "Event"
                 },
                 "to" => [@ap_public],
                 "type" => "Update"
               },
               data
             )
    end
  end
end
