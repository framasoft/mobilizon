# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/web_finger/web_finger_controller_test.exs

defmodule Mobilizon.Web.ActivityPubControllerTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.{Actors, Config}
  alias Mobilizon.Actors.Actor

  alias Mobilizon.Federation.ActivityPub

  alias Mobilizon.Web.ActivityPub.ActorView
  alias Mobilizon.Web.{Endpoint, PageView}
  alias Mobilizon.Web.Router.Helpers, as: Routes

  setup_all do
    Mobilizon.Config.put([:instance, :federating], true)
    :ok
  end

  setup do
    conn = build_conn() |> put_req_header("accept", "application/activity+json")
    {:ok, conn: conn}
  end

  describe "/@:preferred_username" do
    test "it returns a json representation of the actor", %{conn: conn} do
      actor = insert(:actor)

      conn =
        conn
        |> get(Actor.build_url(actor.preferred_username, :page))

      actor = Actors.get_actor!(actor.id)

      assert json_response(conn, 200) ==
               ActorView.render("actor.json", %{actor: actor})
               |> Jason.encode!()
               |> Jason.decode!()
    end
  end

  describe "/events/:uuid" do
    test "it returns a json representation of the event", %{conn: conn} do
      event = insert(:event)

      conn =
        conn
        |> get(Routes.page_url(Endpoint, :event, event.uuid))

      assert json_response(conn, 200) ==
               PageView.render("event.activity-json", %{conn: %{assigns: %{object: event}}})
    end

    test "it returns 404 for non-public events", %{conn: conn} do
      event = insert(:event, visibility: :private)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get(Routes.page_url(Endpoint, :event, event.uuid))

      assert json_response(conn, 404)
    end

    test "it redirects for remote events", %{conn: conn} do
      event = insert(:event, local: false, url: "https://someremote.url/events/here")

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get(Routes.page_url(Endpoint, :event, event.uuid))

      assert redirected_to(conn) == "https://someremote.url/events/here"
    end
  end

  describe "/comments/:uuid" do
    test "it returns a json representation of the comment", %{conn: conn} do
      comment = insert(:comment)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get(Routes.page_url(Endpoint, :comment, comment.uuid))

      assert json_response(conn, 200) ==
               PageView.render("comment.activity-json", %{conn: %{assigns: %{object: comment}}})
    end

    test "it redirects for remote comments", %{conn: conn} do
      comment = insert(:comment, local: false, url: "https://someremote.url/comments/here")

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get(Routes.page_url(Endpoint, :comment, comment.uuid))

      assert redirected_to(conn) == "https://someremote.url/comments/here"
    end

    test "it returns 404 for non-public comments", %{conn: conn} do
      comment = insert(:comment, visibility: :private)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get(Routes.page_url(Endpoint, :comment, comment.uuid))

      assert json_response(conn, 404)
    end
  end

  describe "/@:preferred_username/inbox" do
    test "it inserts an incoming event into the database", %{conn: conn} do
      use_cassette "activity_pub_controller/mastodon-post-activity_actor_call" do
        data = File.read!("test/fixtures/mastodon-post-activity.json") |> Jason.decode!()

        conn =
          conn
          |> assign(:valid_signature, true)
          |> post("#{Endpoint.url()}/inbox", data)

        assert "ok" == json_response(conn, 200)
        :timer.sleep(500)
        assert ActivityPub.fetch_object_from_url(data["object"]["id"])
      end
    end
  end

  describe "/@:preferred_username/outbox" do
    test "it returns a note activity in a collection", %{conn: conn} do
      actor = insert(:actor, visibility: :public)
      comment = insert(:comment, actor: actor)

      conn =
        conn
        |> get(Actor.build_url(actor.preferred_username, :outbox))

      assert json_response(conn, 200)["totalItems"] == 1
      assert json_response(conn, 200)["first"]["orderedItems"] == [comment.url]
    end

    test "it returns an event activity in a collection", %{conn: conn} do
      actor = insert(:actor, visibility: :public)
      event = insert(:event, organizer_actor: actor)

      conn =
        conn
        |> get(Actor.build_url(actor.preferred_username, :outbox))

      assert json_response(conn, 200)["totalItems"] == 1
      assert json_response(conn, 200)["first"]["orderedItems"] == [event.url]
    end

    test "it works for more than 10 events", %{conn: conn} do
      actor = insert(:actor, visibility: :public)

      Enum.each(1..15, fn _ ->
        insert(:event, organizer_actor: actor)
      end)

      result =
        conn
        |> get(Actor.build_url(actor.preferred_username, :outbox))
        |> json_response(200)

      assert length(result["first"]["orderedItems"]) == 10
      assert result["totalItems"] == 15

      result =
        conn
        |> get(Actor.build_url(actor.preferred_username, :outbox, page: 2))
        |> json_response(200)

      assert length(result["orderedItems"]) == 5
    end

    test "it returns an empty collection if the actor has private visibility", %{conn: conn} do
      actor = insert(:actor, visibility: :private)
      insert(:event, organizer_actor: actor)

      conn =
        conn
        |> get(Actor.build_url(actor.preferred_username, :outbox))

      assert json_response(conn, 200)["totalItems"] == 0
      assert json_response(conn, 200)["first"]["orderedItems"] == []
    end

    test "it doesn't returns an event activity in a collection if actor has private visibility",
         %{conn: conn} do
      actor = insert(:actor, visibility: :private)
      insert(:event, organizer_actor: actor)

      conn =
        conn
        |> get(Actor.build_url(actor.preferred_username, :outbox))

      assert json_response(conn, 200)["totalItems"] == 0
    end
  end

  describe "/@actor/followers" do
    test "it returns the followers in a collection", %{conn: conn} do
      actor = insert(:actor, visibility: :public)
      actor2 = insert(:actor)
      Actors.follow(actor, actor2)

      result =
        conn
        |> get(Actor.build_url(actor.preferred_username, :followers))
        |> json_response(200)

      assert result["first"]["orderedItems"] == [actor2.url]
    end

    test "it returns no followers for a private actor", %{conn: conn} do
      actor = insert(:actor, visibility: :private)
      actor2 = insert(:actor)
      Actors.follow(actor, actor2)

      result =
        conn
        |> get(Actor.build_url(actor.preferred_username, :followers))
        |> json_response(200)

      assert result["first"]["orderedItems"] == []
    end

    test "it works for more than 10 actors", %{conn: conn} do
      actor = insert(:actor, visibility: :public)

      Enum.each(1..15, fn _ ->
        other_actor = insert(:actor)
        Actors.follow(actor, other_actor)
      end)

      result =
        conn
        |> get(Actor.build_url(actor.preferred_username, :followers))
        |> json_response(200)

      assert length(result["first"]["orderedItems"]) == 10
      assert result["totalItems"] == 15

      result =
        conn
        |> get(Actor.build_url(actor.preferred_username, :followers, page: 2))
        |> json_response(200)

      assert length(result["orderedItems"]) == 5
    end
  end

  describe "/@actor/following" do
    test "it returns the followings in a collection", %{conn: conn} do
      actor = insert(:actor)
      actor2 = insert(:actor, visibility: :public)
      Actors.follow(actor, actor2)

      result =
        conn
        |> get(Actor.build_url(actor2.preferred_username, :following))
        |> json_response(200)

      assert result["first"]["orderedItems"] == [actor.url]
    end

    test "it returns no followings for a private actor", %{conn: conn} do
      actor = insert(:actor)
      actor2 = insert(:actor, visibility: :private)
      Actors.follow(actor, actor2)

      result =
        conn
        |> get(Actor.build_url(actor2.preferred_username, :following))
        |> json_response(200)

      assert result["first"]["orderedItems"] == []
    end

    test "it works for more than 10 actors", %{conn: conn} do
      actor = insert(:actor, visibility: :public)

      Enum.each(1..15, fn _ ->
        other_actor = insert(:actor)
        Actors.follow(other_actor, actor)
      end)

      result =
        conn
        |> get(Actor.build_url(actor.preferred_username, :following))
        |> json_response(200)

      assert length(result["first"]["orderedItems"]) == 10

      #  assert result["first"]["totalItems"] == 15
      #  assert result["totalItems"] == 15

      result =
        conn
        |> get(Actor.build_url(actor.preferred_username, :following, page: 2))
        |> json_response(200)

      assert length(result["orderedItems"]) == 5
      #  assert result["totalItems"] == 15
    end
  end

  describe "/relay" do
    test "with the relay active, it returns the relay user", %{conn: conn} do
      res =
        conn
        |> get(activity_pub_path(conn, :relay))
        |> json_response(200)

      assert res["id"] =~ "/relay"
    end

    test "with the relay disabled, it returns 404", %{conn: conn} do
      Config.put([:instance, :allow_relay], false)

      conn
      |> get(activity_pub_path(conn, :relay))
      |> json_response(404)
      |> assert

      Config.put([:instance, :allow_relay], true)
    end
  end

  #
  #  describe "/@:preferred_username/following" do
  #    test "it returns the following in a collection", %{conn: conn} do
  #      actor = insert(:actor)
  #      actor2 = insert(:actor)
  #      Mobilizon.Federation.ActivityPub.follow(actor, actor2)

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
  #        Actors.follow(actor, other_actor)
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
