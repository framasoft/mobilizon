defmodule Mobilizon.Web.FeedControllerTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Config
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  describe "/@:preferred_username/feed/atom" do
    test "it returns an RSS representation of the actor's public events if the actor is publicly visible",
         %{conn: conn} do
      actor = insert(:actor, visibility: :public)
      tag1 = insert(:tag, title: "RSS", slug: "rss")
      tag2 = insert(:tag, title: "ATOM", slug: "atom")
      event1 = insert(:event, organizer_actor: actor, tags: [tag1])
      event2 = insert(:event, organizer_actor: actor, tags: [tag1, tag2])

      conn =
        conn
        |> get(
          Endpoint
          |> Routes.feed_url(:actor, actor.preferred_username, "atom")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert response_content_type(conn, :xml) =~ "charset=utf-8"

      {:ok, feed} = ElixirFeedParser.parse(conn.resp_body)

      assert feed.title ==
               actor.preferred_username <> "'s public events feed on #{Config.instance_name()}"

      [entry1, entry2] = entries = feed.entries

      Enum.each(entries, fn entry ->
        assert entry.title in [event1.title, event2.title]
      end)

      # It seems categories takes term instead of Label
      # <category label=\"RSS\" term=\"rss\"/>
      assert entry1.categories == [tag2.title, tag1.title] |> Enum.map(&String.downcase/1)
      assert entry2.categories == [tag1.title] |> Enum.map(&String.downcase/1)
    end

    test "it returns a 404 for the actor's public events Atom feed if the actor is not publicly visible",
         %{conn: conn} do
      actor = insert(:actor, visibility: :private)
      tag1 = insert(:tag, title: "RSS", slug: "rss")
      tag2 = insert(:tag, title: "ATOM", slug: "atom")
      insert(:event, organizer_actor: actor, tags: [tag1])
      insert(:event, organizer_actor: actor, tags: [tag1, tag2])

      conn =
        conn
        |> get(
          Endpoint
          |> Routes.feed_url(:actor, actor.preferred_username, "atom")
          |> URI.decode()
        )

      assert response(conn, 404)
    end

    test "it returns an RSS representation of the actor's public events with the proper accept header",
         %{conn: conn} do
      actor = insert(:actor, visibility: :unlisted)

      conn =
        conn
        |> put_req_header("accept", "application/atom+xml")
        |> get(
          Endpoint
          |> Routes.feed_url(:actor, actor.preferred_username, "atom")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert response_content_type(conn, :xml) =~ "charset=utf-8"
    end

    test "it doesn't return anything for an not existing actor", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/atom+xml")
        |> get("/@notexistent/feed/atom")

      assert response(conn, 404)
    end
  end

  describe "/@:preferred_username/feed/ics" do
    test "it returns an iCalendar representation of the actor's public events with an actor publicly visible",
         %{conn: conn} do
      actor = insert(:actor)
      group = insert(:group, visibility: :public)
      tag1 = insert(:tag, title: "iCalendar", slug: "icalendar")
      tag2 = insert(:tag, title: "Apple", slug: "apple")

      event1 =
        insert(:event,
          organizer_actor: actor,
          attributed_to: group,
          tags: [tag1],
          title: "Event One"
        )

      event2 =
        insert(:event,
          organizer_actor: actor,
          attributed_to: group,
          tags: [tag1, tag2],
          title: "Event Two",
          begins_on: DateTime.add(DateTime.utc_now(), 3_600 * 12 * 4)
        )

      conn =
        conn
        |> get(
          Endpoint
          |> Routes.feed_url(:actor, group.preferred_username, "ics")
          |> URI.decode()
        )

      assert res = response(conn, 200)
      assert res =~ "BEGIN:VCALENDAR"
      assert response_content_type(conn, :calendar) =~ "charset=utf-8"

      [entry2, entry1] = entries = ExIcal.parse(res)

      Enum.each(entries, fn entry ->
        assert entry.summary in [event1.title, event2.title]
      end)

      assert entry1.categories == [tag1.title]
      assert entry2.categories == [tag1.title, tag2.title]
    end

    test "it returns a 404 page for the actor's public events iCal feed with an actor not publicly visible",
         %{conn: conn} do
      actor = insert(:group, visibility: :private)
      tag1 = insert(:tag, title: "iCalendar", slug: "icalendar")
      tag2 = insert(:tag, title: "Apple", slug: "apple")
      insert(:event, organizer_actor: actor, tags: [tag1])
      insert(:event, organizer_actor: actor, tags: [tag1, tag2])

      conn =
        conn
        |> get(
          Endpoint
          |> Routes.feed_url(:actor, actor.preferred_username, "ics")
          |> URI.decode()
        )

      assert response(conn, 404)
    end

    test "it returns an iCalendar representation of the actor's public events with the proper accept header",
         %{conn: conn} do
      actor = insert(:actor, visibility: :unlisted)

      conn =
        conn
        |> put_req_header("accept", "text/calendar")
        |> get(
          Endpoint
          |> Routes.feed_url(:actor, actor.preferred_username, "ics")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "BEGIN:VCALENDAR"
      assert response_content_type(conn, :calendar) =~ "charset=utf-8"
    end

    test "it doesn't return anything for an not existing actor", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "text/calendar")
        |> get("/@notexistent/feed/ics")

      assert response(conn, 404)
    end
  end

  describe "/events/:uuid/export/ics" do
    test "it returns an iCalendar representation of the event", %{conn: conn} do
      tag1 = insert(:tag, title: "iCalendar", slug: "icalendar")
      tag2 = insert(:tag, title: "Apple", slug: "apple")
      event1 = insert(:event, tags: [tag1, tag2])

      conn =
        conn
        |> get(
          Endpoint
          |> Routes.feed_url(:event, event1.uuid, "ics")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "BEGIN:VCALENDAR"
      assert response_content_type(conn, :calendar) =~ "charset=utf-8"

      [entry1] = ExIcal.parse(conn.resp_body)

      assert entry1.summary == event1.title

      assert entry1.categories == [tag1.title, tag2.title]
    end
  end

  describe "/events/going/:token/atom" do
    test "it returns an atom feed of all events for all identities for an user token", %{
      conn: conn
    } do
      user = insert(:user)
      actor1 = insert(:actor, user: user)
      actor2 = insert(:actor, user: user)
      event1 = insert(:event)
      event2 = insert(:event)
      insert(:participant, event: event1, actor: actor1)
      insert(:participant, event: event2, actor: actor2)
      feed_token = insert(:feed_token, user: user, actor: nil)

      conn =
        conn
        |> get(
          Endpoint
          |> Routes.feed_url(:going, ShortUUID.encode!(feed_token.token), "atom")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert response_content_type(conn, :xml) =~ "charset=utf-8"

      {:ok, feed} = ElixirFeedParser.parse(conn.resp_body)

      assert feed.title == "Feed for #{user.email} on #{Config.instance_name()}"

      entries = feed.entries

      Enum.each(entries, fn entry ->
        assert entry.title in [event1.title, event2.title]
      end)
    end

    test "it returns an atom feed of all events a single identity for an actor token", %{
      conn: conn
    } do
      user = insert(:user)
      actor1 = insert(:actor, user: user)
      actor2 = insert(:actor, user: user)
      event1 = insert(:event)
      event2 = insert(:event)
      insert(:participant, event: event1, actor: actor1)
      insert(:participant, event: event2, actor: actor2)
      feed_token = insert(:feed_token, user: user, actor: actor1)

      conn =
        conn
        |> put_req_header("accept", "application/atom+xml")
        |> get(
          Endpoint
          |> Routes.feed_url(:going, ShortUUID.encode!(feed_token.token), "atom")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert response_content_type(conn, :xml) =~ "charset=utf-8"

      {:ok, feed} = ElixirFeedParser.parse(conn.resp_body)

      assert feed.title ==
               "#{actor1.preferred_username}'s private events feed on #{Config.instance_name()}"

      [entry] = feed.entries
      assert entry.title == event1.title
    end

    test "it returns 404 for an not existing feed", %{conn: conn} do
      conn =
        conn
        |> get(
          Endpoint
          |> Routes.feed_url(:going, "not existing", "atom")
          |> URI.decode()
        )

      assert response(conn, 404)
    end
  end

  describe "/events/going/:token/ics" do
    test "it returns an ical feed of all events for all identities for an user token", %{
      conn: conn
    } do
      user = insert(:user)
      actor1 = insert(:actor, user: user)
      actor2 = insert(:actor, user: user)
      event1 = insert(:event)
      event2 = insert(:event)
      insert(:participant, event: event1, actor: actor1)
      insert(:participant, event: event2, actor: actor2)
      feed_token = insert(:feed_token, user: user, actor: nil)

      conn =
        conn
        |> put_req_header("accept", "text/calendar")
        |> get(
          Endpoint
          |> Routes.feed_url(:going, ShortUUID.encode!(feed_token.token), "ics")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "BEGIN:VCALENDAR"
      assert response_content_type(conn, :calendar) =~ "charset=utf-8"

      entries = ExIcal.parse(conn.resp_body)

      Enum.each(entries, fn entry ->
        assert entry.summary in [event1.title, event2.title]
      end)
    end

    test "it returns an ical feed of all events a single identity for an actor token", %{
      conn: conn
    } do
      user = insert(:user)
      actor1 = insert(:actor, user: user)
      actor2 = insert(:actor, user: user)
      event1 = insert(:event)
      event2 = insert(:event)
      insert(:participant, event: event1, actor: actor1)
      insert(:participant, event: event2, actor: actor2)
      feed_token = insert(:feed_token, user: user, actor: actor1)

      conn =
        conn
        |> put_req_header("accept", "text/calendar")
        |> get(
          Endpoint
          |> Routes.feed_url(:going, ShortUUID.encode!(feed_token.token), "ics")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "BEGIN:VCALENDAR"
      assert response_content_type(conn, :calendar) =~ "charset=utf-8"

      [entry1] = ExIcal.parse(conn.resp_body)
      assert entry1.summary == event1.title
      assert entry1.categories == event1.tags |> Enum.map(& &1.title)
    end

    test "it returns 404 for an not existing feed", %{conn: conn} do
      conn =
        conn
        |> get(
          Endpoint
          |> Routes.feed_url(:going, "not existing", "ics")
          |> URI.decode()
        )

      assert response(conn, 404)
    end
  end
end
