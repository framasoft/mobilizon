defmodule MobilizonWeb.ActivityPubControllerTest do
  use MobilizonWeb.ConnCase
  import Mobilizon.Factory
  alias MobilizonWeb.ActivityPub.{ActorView, ObjectView}
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

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

  describe "/comments/:uuid" do
    test "it returns a json representation of the comment", %{conn: conn} do
      comment = insert(:comment)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get("/comments/#{comment.uuid}")

      assert json_response(conn, 200) ==
               ObjectView.render("comment.json", %{comment: comment |> Utils.make_comment_data()})
    end

    # TODO !
    # test "it returns 404 for non-public comments", %{conn: conn} do
    #   event = insert(:event, public: false)

    #   conn =
    #     conn
    #     |> put_req_header("accept", "application/activity+json")
    #     |> get("/events/#{event.uuid}")

    #   assert json_response(conn, 404)
    # end
  end

  describe "/@:preferred_username/inbox" do
    test "it inserts an incoming event into the database", %{conn: conn} do
      use_cassette "activity_pub_controller/mastodon-post-activity_actor_call" do
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

  describe "/@actor/followers" do
    test "it returns the followers in a collection", %{conn: conn} do
      actor = insert(:actor)
      actor2 = insert(:actor)
      Actor.follow(actor, actor2)

      result =
        conn
        |> get("/@#{actor.preferred_username}/followers")
        |> json_response(200)

      assert result["first"]["orderedItems"] == [actor2.url]
    end

    test "it works for more than 10 actors", %{conn: conn} do
      actor = insert(:actor)

      Enum.each(1..15, fn _ ->
        other_actor = insert(:actor)
        Actor.follow(actor, other_actor)
      end)

      result =
        conn
        |> get("/@#{actor.preferred_username}/followers")
        |> json_response(200)

      assert length(result["first"]["orderedItems"]) == 10
      #  assert result["first"]["totalItems"] == 15
      #  assert result["totalItems"] == 15

      result =
        conn
        |> get("/@#{actor.preferred_username}/followers?page=2")
        |> json_response(200)

      assert length(result["orderedItems"]) == 5
      #  assert result["totalItems"] == 15
    end
  end

  describe "/@actor/following" do
    test "it returns the followings in a collection", %{conn: conn} do
      actor = insert(:actor)
      actor2 = insert(:actor)
      Actor.follow(actor, actor2)

      result =
        conn
        |> get("/@#{actor2.preferred_username}/following")
        |> json_response(200)

      assert result["first"]["orderedItems"] == [actor.url]
    end

    test "it works for more than 10 actors", %{conn: conn} do
      actor = insert(:actor)

      Enum.each(1..15, fn _ ->
        other_actor = insert(:actor)
        Actor.follow(other_actor, actor)
      end)

      result =
        conn
        |> get("/@#{actor.preferred_username}/following")
        |> json_response(200)

      assert length(result["first"]["orderedItems"]) == 10
      #  assert result["first"]["totalItems"] == 15
      #  assert result["totalItems"] == 15

      result =
        conn
        |> get("/@#{actor.preferred_username}/following?page=2")
        |> json_response(200)

      assert length(result["orderedItems"]) == 5
      #  assert result["totalItems"] == 15
    end
  end

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
