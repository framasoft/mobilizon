defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.FollowTest do
  use Mobilizon.DataCase

  import ExUnit.CaptureLog
  import Mobilizon.Factory
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Follower
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Activity, Transmogrifier}

  describe "handle incoming follow requests" do
    test "it works only for groups" do
      actor = insert(:actor)

      data =
        File.read!("test/fixtures/mastodon-follow-activity.json")
        |> Jason.decode!()
        |> Map.put("object", actor.url)

      assert capture_log(fn ->
               :error = Transmogrifier.handle_incoming(data)
             end) =~ "Only group and instances can be followed"

      actor = Actors.get_actor_with_preload(actor.id)
      refute Actors.is_following(Actors.get_actor_by_url!(data["actor"], true), actor)
    end

    test "it works for incoming follow requests" do
      actor = insert(:group)

      data =
        File.read!("test/fixtures/mastodon-follow-activity.json")
        |> Jason.decode!()
        |> Map.put("object", actor.url)

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

      assert data["actor"] == "https://social.tcit.fr/users/tcit"
      assert data["type"] == "Follow"
      assert data["id"] == "https://social.tcit.fr/users/tcit#follows/2"

      actor = Actors.get_actor_with_preload(actor.id)
      assert Actors.is_following(Actors.get_actor_by_url!(data["actor"], true), actor)
    end

    test "it rejects activities without a valid ID" do
      actor = insert(:group)

      data =
        File.read!("test/fixtures/mastodon-follow-activity.json")
        |> Jason.decode!()
        |> Map.put("object", actor.url)
        |> Map.put("id", "")

      :error = Transmogrifier.handle_incoming(data)
    end

    #     test "it works for incoming follow requests from hubzilla" do
    #       user = insert(:user)

    #       data =
    #         File.read!("test/fixtures/hubzilla-follow-activity.json")
    #         |> Jason.decode!()
    #         |> Map.put("object", user.ap_id)
    #         |> Utils.normalize_params()

    #       {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(data)

    #       assert data["actor"] == "https://hubzilla.example.org/channel/kaniini"
    #       assert data["type"] == "Follow"
    #       assert data["id"] == "https://hubzilla.example.org/channel/kaniini#follows/2"
    #       assert User.is_following(User.get_by_ap_id(data["actor"]), user)
    #     end
  end

  describe "handle incoming follow accept activities" do
    test "it works for incoming accepts" do
      follower = insert(:actor)
      followed = insert(:group, manually_approves_followers: false)

      refute Actors.is_following(follower, followed)

      {:ok, follow_activity, _} = ActivityPub.follow(follower, followed)
      assert Actors.is_following(follower, followed)

      follow_object_id = follow_activity.data["id"]

      assert %Follower{} = Actors.get_follower_by_url(follow_object_id)

      accept_data =
        File.read!("test/fixtures/mastodon-accept-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", followed.url)

      object =
        accept_data["object"]
        |> Map.put("actor", follower.url)
        |> Map.put("id", follow_object_id)

      accept_data = Map.put(accept_data, "object", object)

      :error = Transmogrifier.handle_incoming(accept_data)

      {:ok, follower} = Actors.get_actor_by_url(follower.url)

      assert Actors.is_following(follower, followed)
    end

    test "it works for incoming accepts which were pre-accepted" do
      follower = insert(:actor)
      followed = insert(:group, manually_approves_followers: true)

      refute Actors.is_following(follower, followed)

      {:ok, follow_activity, _} = ActivityPub.follow(follower, followed)
      assert Actors.is_following(follower, followed)

      follow_object_id = follow_activity.data["id"]

      assert %Follower{} = Actors.get_follower_by_url(follow_object_id)

      accept_data =
        File.read!("test/fixtures/mastodon-accept-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", followed.url)

      object =
        accept_data["object"]
        |> Map.put("actor", follower.url)
        |> Map.put("id", follow_object_id)

      accept_data = Map.put(accept_data, "object", object)

      {:ok, activity, _} = Transmogrifier.handle_incoming(accept_data)
      refute activity.local

      assert activity.data["object"]["id"] == follow_activity.data["id"]

      {:ok, follower} = Actors.get_actor_by_url(follower.url)

      assert Actors.is_following(follower, followed)
    end

    test "it works for incoming accepts which are referenced by IRI only" do
      follower = insert(:actor)
      followed = insert(:group, manually_approves_followers: true)

      {:ok, follow_activity, _} = ActivityPub.follow(follower, followed)

      accept_data =
        File.read!("test/fixtures/mastodon-accept-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", followed.url)
        |> Map.put("object", follow_activity.data["id"])

      {:ok, activity, _} = Transmogrifier.handle_incoming(accept_data)
      assert activity.data["object"]["id"] == follow_activity.data["id"]
      assert activity.data["object"]["id"] =~ "/follow/"
      assert activity.data["id"] =~ "/accept/follow/"

      {:ok, follower} = Actors.get_actor_by_url(follower.url)

      assert Actors.is_following(follower, followed)
    end

    test "it fails for incoming accepts which cannot be correlated" do
      follower = insert(:actor)
      followed = insert(:group)

      accept_data =
        File.read!("test/fixtures/mastodon-accept-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", followed.url)

      accept_data =
        Map.put(accept_data, "object", Map.put(accept_data["object"], "actor", follower.url))

      :error = Transmogrifier.handle_incoming(accept_data)

      {:ok, follower} = Actors.get_actor_by_url(follower.url)

      refute Actors.is_following(follower, followed)
    end
  end

  describe "handle incoming follow reject activities" do
    test "it fails for incoming rejects which cannot be correlated" do
      follower = insert(:actor)
      followed = insert(:group)

      accept_data =
        File.read!("test/fixtures/mastodon-reject-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", followed.url)

      accept_data =
        Map.put(accept_data, "object", Map.put(accept_data["object"], "actor", follower.url))

      :error = Transmogrifier.handle_incoming(accept_data)

      {:ok, follower} = Actors.get_actor_by_url(follower.url)

      refute Actors.is_following(follower, followed)
    end

    test "it works for incoming rejects which are referenced by IRI only" do
      follower = insert(:actor)
      followed = insert(:group)

      {:ok, follow_activity, _} = ActivityPub.follow(follower, followed)

      assert Actors.is_following(follower, followed)

      reject_data =
        File.read!("test/fixtures/mastodon-reject-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", followed.url)
        |> Map.put("object", follow_activity.data["id"])

      {:ok, %Activity{data: _}, _} = Transmogrifier.handle_incoming(reject_data)

      refute Actors.is_following(follower, followed)
    end
  end
end
