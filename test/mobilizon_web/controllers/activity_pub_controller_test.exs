defmodule MobilizonWeb.ActivityPubControllerTest do
  use MobilizonWeb.ConnCase
  import Mobilizon.Factory
  alias MobilizonWeb.ActivityPub.{ActorView, ObjectView}
  alias Mobilizon.Actors
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils

  describe "/@:preferred_username" do
    test "it returns a json representation of the actor", %{conn: conn} do
      actor = insert(:actor)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get("/@#{actor.preferred_username}")

      actor = Actors.get_actor!(actor.id)

      assert json_response(conn, 200) == ActorView.render("actor.json", %{actor: actor})
    end
  end

  describe "/events/:uuid" do
    test "it returns a json representation of the event", %{conn: conn} do
      event = insert(:event)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get("/events/#{event.uuid}")

      assert json_response(conn, 200) ==
               ObjectView.render("event.json", %{event: event |> Utils.make_event_data()})
    end

    test "it returns 404 for non-public events", %{conn: conn} do
      event = insert(:event, public: false)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get("/events/#{event.uuid}")

      assert json_response(conn, 404)
    end
  end

  describe "/@:preferred_username/inbox" do
    test "it inserts an incoming event into the database", %{conn: conn} do
      data = File.read!("test/fixtures/mastodon-post-activity.json") |> Poison.decode!()

      conn =
        conn
        |> assign(:valid_signature, true)
        |> put_req_header("content-type", "application/activity+json")
        |> post("/inbox", data)

      assert "ok" == json_response(conn, 200)
      :timer.sleep(500)
      assert ActivityPub.fetch_object_from_url(data["object"]["id"])
    end
  end

  describe "/@:preferred_username/outbox" do
    test "it returns a note activity in a collection", %{conn: conn} do
      actor = insert(:actor)
      comment = insert(:comment, actor: actor)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get("/@#{actor.preferred_username}/outbox")

      assert response(conn, 200) =~ comment.text
    end

    test "it returns an event activity in a collection", %{conn: conn} do
      actor = insert(:actor)
      event = insert(:event, organizer_actor: actor)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get("/@#{actor.preferred_username}/outbox")

      assert response(conn, 200) =~ event.title
    end
  end

  #  describe "/actors/:nickname/followers" do
  #    test "it returns the followers in a collection", %{conn: conn} do
  #      user = insert(:user)
  #      user_two = insert(:user)
  #      User.follow(user, user_two)
  #
  #      result =
  #        conn
  #        |> get("/users/#{user_two.nickname}/followers")
  #        |> json_response(200)
  #
  #      assert result["first"]["orderedItems"] == [user.ap_id]
  #    end
  #
  #    test "it works for more than 10 users", %{conn: conn} do
  #      user = insert(:user)
  #
  #      Enum.each(1..15, fn _ ->
  #        other_user = insert(:user)
  #        User.follow(other_user, user)
  #      end)
  #
  #      result =
  #        conn
  #        |> get("/users/#{user.nickname}/followers")
  #        |> json_response(200)
  #
  #      assert length(result["first"]["orderedItems"]) == 10
  #      assert result["first"]["totalItems"] == 15
  #      assert result["totalItems"] == 15
  #
  #      result =
  #        conn
  #        |> get("/users/#{user.nickname}/followers?page=2")
  #        |> json_response(200)
  #
  #      assert length(result["orderedItems"]) == 5
  #      assert result["totalItems"] == 15
  #    end
  #  end
  #
  #  describe "/@:preferred_username/following" do
  #    test "it returns the following in a collection", %{conn: conn} do
  #      actor = insert(:actor)
  #      actor2 = insert(:actor)
  #      Mobilizon.Service.ActivityPub.follow(actor, actor2)

  #      result =
  #        conn
  #        |> get("/@#{actor.preferred_username}/following")
  #        |> json_response(200)

  #      assert result["first"]["orderedItems"] == [actor2.url]
  #    end

  #    test "it works for more than 10 actors", %{conn: conn} do
  #      actor = insert(:actor)

  #      Enum.each(1..15, fn _ ->
  #        actor = Repo.get(Actor, actor.id)
  #        other_actor = insert(:actor)
  #        Actor.follow(actor, other_actor)
  #      end)

  #      result =
  #        conn
  #        |> get("/@#{actor.preferred_username}/following")
  #        |> json_response(200)

  #      assert length(result["first"]["orderedItems"]) == 10
  #      assert result["first"]["totalItems"] == 15
  #      assert result["totalItems"] == 15

  #      result =
  #        conn
  #        |> get("/@#{actor.preferred_username}/following?page=2")
  #        |> json_response(200)

  #      assert length(result["orderedItems"]) == 5
  #      assert result["totalItems"] == 15
  #    end
  #  end
end
