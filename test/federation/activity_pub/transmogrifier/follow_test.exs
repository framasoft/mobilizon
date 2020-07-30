defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.FollowTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  alias Mobilizon.Actors
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Activity, Transmogrifier}

  describe "handle incoming follow accept activities" do
    test "it works for incoming accepts which were pre-accepted" do
      follower = insert(:actor)
      followed = insert(:actor)

      refute Actors.is_following(follower, followed)

      {:ok, follow_activity, _} = ActivityPub.follow(follower, followed)
      assert Actors.is_following(follower, followed)

      accept_data =
        File.read!("test/fixtures/mastodon-accept-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", followed.url)

      object =
        accept_data["object"]
        |> Map.put("actor", follower.url)
        |> Map.put("id", follow_activity.data["id"])

      accept_data = Map.put(accept_data, "object", object)

      {:ok, activity, _} = Transmogrifier.handle_incoming(accept_data)
      refute activity.local

      assert activity.data["object"]["id"] == follow_activity.data["id"]

      {:ok, follower} = Actors.get_actor_by_url(follower.url)

      assert Actors.is_following(follower, followed)
    end

    test "it works for incoming accepts which are referenced by IRI only" do
      follower = insert(:actor)
      followed = insert(:actor)

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
      followed = insert(:actor)

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
      followed = insert(:actor)

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
      followed = insert(:actor)

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
