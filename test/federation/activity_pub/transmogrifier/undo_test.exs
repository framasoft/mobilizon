defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.UndoTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  import Mox
  alias Mobilizon.Actors
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Federation.ActivityPub.{Activity, Transmogrifier}
  alias Mobilizon.Service.HTTP.ActivityPub.Mock

  describe "handle incoming undo activities" do
    test "it works for incoming unannounces with an existing notice" do
      comment = insert(:comment)

      announce_data =
        File.read!("test/fixtures/mastodon-announce.json")
        |> Jason.decode!()
        |> Map.put("object", comment.url)

      actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{method: :get, url: "https://framapiaf.org/users/Framasoft"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}
      end)

      {:ok, _, %Comment{}} = Transmogrifier.handle_incoming(announce_data)

      data =
        File.read!("test/fixtures/mastodon-undo-announce.json")
        |> Jason.decode!()
        |> Map.put("object", announce_data)
        |> Map.put("actor", announce_data["actor"])

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

      assert data["type"] == "Undo"
      assert data["object"]["type"] == "Announce"
      assert data["object"]["object"]["id"] == comment.url

      assert data["object"]["id"] ==
               "https://framapiaf.org/users/peertube/statuses/104584600044284729/activity"
    end

    test "it works for incomming unfollows with an existing follow" do
      actor = insert(:group)

      follow_data =
        File.read!("test/fixtures/mastodon-follow-activity.json")
        |> Jason.decode!()
        |> Map.put("object", actor.url)

      actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()
        |> Map.put("id", "https://social.tcit.fr/users/tcit")

      Mock
      |> expect(:call, fn
        %{method: :get, url: "https://social.tcit.fr/users/tcit"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}
      end)

      {:ok, %Activity{data: _, local: false}, _} = Transmogrifier.handle_incoming(follow_data)

      data =
        File.read!("test/fixtures/mastodon-unfollow-activity.json")
        |> Jason.decode!()
        |> Map.put("object", follow_data)

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

      assert data["type"] == "Undo"
      assert data["object"]["type"] == "Follow"
      assert data["object"]["object"] == actor.url
      assert data["actor"] == "https://social.tcit.fr/users/tcit"

      {:ok, followed} = Actors.get_actor_by_url(data["actor"])
      refute Actors.is_following(followed, actor)
    end
  end
end
