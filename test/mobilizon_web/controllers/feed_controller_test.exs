defmodule MobilizonWeb.FeedControllerTest do
  use MobilizonWeb.ConnCase
  import Mobilizon.Factory
  alias MobilizonWeb.Router.Helpers, as: Routes
  alias MobilizonWeb.Endpoint

  describe "/@:preferred_username/feed/atom" do
    test "it returns an RSS representation of the actor's public events", %{conn: conn} do
      actor = insert(:actor)
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

      assert feed.title == actor.preferred_username <> "'s public events feed"

      [entry1, entry2] = entries = feed.entries

      Enum.each(entries, fn entry ->
        assert entry.title in [event1.title, event2.title]
      end)

      assert entry1.categories == [tag2.slug, tag1.slug]
      assert entry2.categories == [tag1.slug]
    end

    test "it returns an RSS representation of the actor's public events with the proper accept header",
         %{conn: conn} do
      actor = insert(:actor)

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
    test "it returns an iCalendar representation of the actor's public events", %{conn: conn} do
      actor = insert(:actor)
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

      assert entry1.categories == [event1.category, tag1.slug]
      assert entry2.categories == [event2.category, tag1.slug, tag2.slug]
    end

    test "it returns an iCalendar representation of the actor's public events with the proper accept header",
         %{conn: conn} do
      actor = insert(:actor)

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

      assert entry1.categories == [event1.category, tag1.slug, tag2.slug]
    end
  end
end
