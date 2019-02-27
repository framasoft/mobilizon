defmodule MobilizonWeb.FeedControllerTest do
  use MobilizonWeb.ConnCase
  import Mobilizon.Factory

  describe "/@:preferred_username.atom" do
    test "it returns an RSS representation of the actor's public events", %{conn: conn} do
      actor = insert(:actor)
      event1 = insert(:event, organizer_actor: actor)
      event2 = insert(:event, organizer_actor: actor)

      conn =
        conn
        |> put_req_header("accept", "application/atom+xml")
        |> get("/@#{actor.preferred_username}.atom")

      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert response_content_type(conn, :xml) =~ "charset=utf-8"

      {:ok, feed, _} = FeederEx.parse(conn.resp_body)

      assert feed.title == actor.preferred_username <> "'s public events feed"

      Enum.each(feed.entries, fn entry ->
        assert entry.title in [event1.title, event2.title]
      end)
    end

    test "it doesn't return anything for an not existing actor", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/atom+xml")
        |> get("/@notexistent.atom")

      assert response(conn, 404) == "Not found"
    end
  end
end
