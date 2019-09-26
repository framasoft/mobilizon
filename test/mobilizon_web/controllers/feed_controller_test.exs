defmodule MobilizonWeb.FeedControllerTest do
  use MobilizonWeb.ConnCase
  import Mobilizon.Factory
  alias MobilizonWeb.Router.Helpers, as: Routes
  alias MobilizonWeb.Endpoint

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
          Routes.feed_url(Endpoint, :actor, actor.preferred_username, "atom")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert response_content_type(conn, :xml) =~ "charset=utf-8"

      {:ok, feed} = ElixirFeedParser.parse(conn.resp_body)

      assert feed.title == actor.preferred_username <> "'s public events feed on Mobilizon"

      [entry1, entry2] = entries = feed.entries

      Enum.each(entries, fn entry ->
        assert entry.title in [event1.title, event2.title]
      end)

      assert entry1.categories == [tag2.slug, tag1.slug]
      assert entry2.categories == [tag1.slug]
    end

    test "it returns a 404 for the actor's public events Atom feed if the actor is not publicly visible",
         %{conn: conn} do
      actor = insert(:actor)
      tag1 = insert(:tag, title: "RSS", slug: "rss")
      tag2 = insert(:tag, title: "ATOM", slug: "atom")
      insert(:event, organizer_actor: actor, tags: [tag1])
      insert(:event, organizer_actor: actor, tags: [tag1, tag2])

      conn =
        conn
        |> get(
          Routes.feed_url(Endpoint, :actor, actor.preferred_username, "atom")
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
          Routes.feed_url(Endpoint, :actor, actor.preferred_username, "atom")
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
      actor = insert(:actor, visibility: :public)
      tag1 = insert(:tag, title: "iCalendar", slug: "icalendar")
      tag2 = insert(:tag, title: "Apple", slug: "apple")
      event1 = insert(:event, organizer_actor: actor, tags: [tag1])
      event2 = insert(:event, organizer_actor: actor, tags: [tag1, tag2])

      conn =
        conn
        |> get(
          Routes.feed_url(Endpoint, :actor, actor.preferred_username, "ics")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "BEGIN:VCALENDAR"
      assert response_content_type(conn, :calendar) =~ "charset=utf-8"

      [entry1, entry2] = entries = ExIcal.parse(conn.resp_body)

      Enum.each(entries, fn entry ->
        assert entry.summary in [event1.title, event2.title]
      end)

      assert entry1.categories == [tag1.slug]
      assert entry2.categories == [tag1.slug, tag2.slug]
    end

    test "it returns a 404 page for the actor's public events iCal feed with an actor not publicly visible",
         %{conn: conn} do
      actor = insert(:actor, visibility: :private)
      tag1 = insert(:tag, title: "iCalendar", slug: "icalendar")
      tag2 = insert(:tag, title: "Apple", slug: "apple")
      insert(:event, organizer_actor: actor, tags: [tag1])
      insert(:event, organizer_actor: actor, tags: [tag1, tag2])

      conn =
        conn
        |> get(
          Routes.feed_url(Endpoint, :actor, actor.preferred_username, "ics")
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
          Routes.feed_url(Endpoint, :actor, actor.preferred_username, "ics")
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
          Routes.feed_url(Endpoint, :event, event1.uuid, "ics")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "BEGIN:VCALENDAR"
      assert response_content_type(conn, :calendar) =~ "charset=utf-8"

      [entry1] = ExIcal.parse(conn.resp_body)

      assert entry1.summary == event1.title

      assert entry1.categories == [tag1.slug, tag2.slug]
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
          Routes.feed_url(Endpoint, :going, feed_token.token, "atom")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert response_content_type(conn, :xml) =~ "charset=utf-8"

      {:ok, feed} = ElixirFeedParser.parse(conn.resp_body)

      assert feed.title == "Feed for #{user.email} on Mobilizon"

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
          Routes.feed_url(Endpoint, :going, feed_token.token, "atom")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert response_content_type(conn, :xml) =~ "charset=utf-8"

      {:ok, feed} = ElixirFeedParser.parse(conn.resp_body)

      assert feed.title == "#{actor1.preferred_username}'s private events feed on Mobilizon"

      [entry] = feed.entries
      assert entry.title == event1.title
    end

    test "it returns 404 for an not existing feed", %{conn: conn} do
      conn =
        conn
        |> get(
          Routes.feed_url(Endpoint, :going, "not existing", "atom")
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
          Routes.feed_url(Endpoint, :going, feed_token.token, "ics")
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
          Routes.feed_url(Endpoint, :going, feed_token.token, "ics")
          |> URI.decode()
        )

      assert response(conn, 200) =~ "BEGIN:VCALENDAR"
      assert response_content_type(conn, :calendar) =~ "charset=utf-8"

      [entry1] = ExIcal.parse(conn.resp_body)
      assert entry1.summary == event1.title
      assert entry1.categories == event1.tags |> Enum.map(& &1.slug)
    end

    test "it returns 404 for an not existing feed", %{conn: conn} do
      conn =
        conn
        |> get(
          Routes.feed_url(Endpoint, :going, "not existing", "ics")
          |> URI.decode()
        )

      assert response(conn, 404)
    end
  end
end
