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

      assert res = json_response(conn, 200)

      assert res["totalItems"] == 1
      assert res["first"]["orderedItems"] |> Enum.map(& &1["object"]["id"]) == [comment.url]
    end

    test "it returns an event activity in a collection", %{conn: conn} do
      actor = insert(:actor, visibility: :public)
      event = insert(:event, organizer_actor: actor)

      conn =
        conn
        |> get(Actor.build_url(actor.preferred_username, :outbox))

      assert res = json_response(conn, 200)

      assert res["totalItems"] == 1
      assert res["first"]["orderedItems"] |> Enum.map(& &1["object"]["id"]) == [event.url]
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

  describe "/@actor/members for a group" do
    test "it returns the members in a group", %{conn: conn} do
      actor = insert(:actor)

      assert {:ok, %Actor{} = group} =
               Actors.create_group(%{
                 creator_actor_id: actor.id,
                 preferred_username: "my_group",
                 local: true
               })

      result =
        conn
        |> assign(:actor, actor)
        |> get(Actor.build_url(group.preferred_username, :members))
        |> json_response(200)

      assert hd(result["first"]["orderedItems"])["actor"] == actor.url
      assert hd(result["first"]["orderedItems"])["object"] == group.url
      assert hd(result["first"]["orderedItems"])["role"] == "administrator"
      assert hd(result["first"]["orderedItems"])["type"] == "Member"
    end

    test "it returns no members when not a member of the group", %{conn: conn} do
      actor = insert(:actor)
      actor2 = insert(:actor)

      assert {:ok, %Actor{} = group} =
               Actors.create_group(%{
                 creator_actor_id: actor.id,
                 preferred_username: "my_group",
                 local: true
               })

      result =
        conn
        |> assign(:actor, actor2)
        |> get(Actor.build_url(group.preferred_username, :members))
        |> json_response(200)

      assert result["first"]["orderedItems"] == []
    end

    test "it works for more than 10 actors", %{conn: conn} do
      actor = insert(:actor, preferred_username: "my_admin")

      assert {:ok, %Actor{} = group} =
               Actors.create_group(%{
                 creator_actor_id: actor.id,
                 preferred_username: "my_group",
                 local: true
               })

      Enum.each(1..15, fn _ ->
        other_actor = insert(:actor)
        insert(:member, actor: other_actor, parent: group, role: :member)
      end)

      result =
        conn
        |> assign(:actor, actor)
        |> get(Actor.build_url(group.preferred_username, :members))
        |> json_response(200)

      assert length(result["first"]["orderedItems"]) == 10
      # 15 members + 1 admin
      assert result["totalItems"] == 16

      result =
        conn
        |> assign(:actor, actor)
        |> get(Actor.build_url(group.preferred_username, :members, page: 2))
        |> json_response(200)

      assert length(result["orderedItems"]) == 6
    end

    test "it returns members for a private group but request is signed by an actor", %{conn: conn} do
      actor_group_admin = insert(:actor)
      actor_applicant = insert(:actor)

      assert {:ok, %Actor{} = group} =
               Actors.create_group(%{
                 creator_actor_id: actor_group_admin.id,
                 preferred_username: "my_group",
                 local: true
               })

      insert(:member, actor: actor_applicant, parent: group, role: :member)

      result =
        conn
        |> assign(:actor, actor_applicant)
        |> get(Actor.build_url(group.preferred_username, :members))
        |> json_response(200)

      assert members = result["first"]["orderedItems"]

      admin_member =
        Enum.find(
          members,
          fn member ->
            member["actor"] == actor_group_admin.url
          end
        )

      member =
        Enum.find(
          members,
          fn member ->
            member["actor"] == actor_applicant.url
          end
        )

      assert admin_member["role"] == "administrator"

      assert member["role"] == "member" ||
               assert(result["totalItems"] == 2)
    end
  end

  describe "/member/:uuid" do
    test "it returns a json representation of the member", %{conn: conn} do
      group = insert(:group)
      remote_actor_2 = insert(:actor, domain: "remote3.tld")
      insert(:member, actor: remote_actor_2, parent: group, role: :member)

      member =
        insert(:member,
          parent: group,
          url: "https://someremote.url/member/here"
        )

      conn =
        conn
        |> assign(:actor, remote_actor_2)
        |> put_req_header("accept", "application/activity+json")
        |> get(Routes.activity_pub_url(Endpoint, :member, member.id))

      assert json_response(conn, 200) ==
               ActorView.render("member.json", %{member: member})
    end

    test "it redirects for remote comments", %{conn: conn} do
      group = insert(:group, domain: "remote1.tld")
      remote_actor = insert(:actor, domain: "remote2.tld")
      remote_actor_2 = insert(:actor, domain: "remote3.tld")
      insert(:member, actor: remote_actor_2, parent: group, role: :member)

      member =
        insert(:member,
          actor: remote_actor,
          parent: group,
          url: "https://someremote.url/member/here"
        )

      conn =
        conn
        |> assign(:actor, remote_actor_2)
        |> put_req_header("accept", "application/activity+json")
        |> get(Routes.activity_pub_url(Endpoint, :member, member.id))

      assert redirected_to(conn) == "https://someremote.url/member/here"
    end

    test "it returns 404 if the fetch is not authenticated", %{conn: conn} do
      member = insert(:member)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get(Routes.activity_pub_url(Endpoint, :member, member.id))

      assert json_response(conn, 404)
    end
  end
end
