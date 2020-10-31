defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.CommentsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  import Mox
  import ExUnit.CaptureLog
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.{Activity, Transmogrifier}
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Service.HTTP.ActivityPub.Mock

  describe "handle incoming comments" do
    setup :verify_on_exit!

    test "it ignores an incoming comment if we already have it" do
      comment = insert(:comment)
      comment = Repo.preload(comment, [:attributed_to])

      activity = %{
        "type" => "Create",
        "to" => ["https://www.w3.org/ns/activitystreams#Public"],
        "actor" => comment.actor.url,
        "object" => Convertible.model_to_as(comment)
      }

      data =
        File.read!("test/fixtures/mastodon-post-activity.json")
        |> Jason.decode!()
        |> Map.put("object", activity["object"])

      assert {:ok, nil, _} = Transmogrifier.handle_incoming(data)
    end

    test "it fetches replied-to activities if we don't have them" do
      data =
        File.read!("test/fixtures/mastodon-post-activity.json")
        |> Jason.decode!()

      reply_to_url = "https://blob.cat/objects/02fdea3d-932c-4348-9ecb-3f9eb3fbdd94"

      object =
        data["object"]
        |> Map.put("inReplyTo", reply_to_url)

      data =
        data
        |> Map.put("object", object)

      reply_to_data =
        File.read!("test/fixtures/pleroma-comment-object.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{method: :get, url: ^reply_to_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: reply_to_data}}
      end)

      {:ok, returned_activity, _} = Transmogrifier.handle_incoming(data)

      %Comment{} =
        origin_comment =
        Discussions.get_comment_from_url(
          "https://blob.cat/objects/02fdea3d-932c-4348-9ecb-3f9eb3fbdd94"
        )

      assert returned_activity.data["object"]["inReplyTo"] ==
               "https://blob.cat/objects/02fdea3d-932c-4348-9ecb-3f9eb3fbdd94"

      assert returned_activity.data["object"]["inReplyTo"] == origin_comment.url
    end

    test "it doesn't saves replies to an event if the event doesn't accept comments" do
      data =
        File.read!("test/fixtures/mastodon-post-activity.json")
        |> Jason.decode!()

      %Event{url: reply_to_url} = insert(:event, options: %{comment_moderation: :closed})

      object =
        data["object"]
        |> Map.put("inReplyTo", reply_to_url)

      data =
        data
        |> Map.put("object", object)

      :error = Transmogrifier.handle_incoming(data)
    end

    @url_404 "https://404.site/whatever"
    test "it does not crash if the object in inReplyTo can't be fetched" do
      data =
        File.read!("test/fixtures/mastodon-post-activity.json")
        |> Jason.decode!()

      object =
        data["object"]
        |> Map.put("inReplyTo", @url_404)

      data =
        data
        |> Map.put("object", object)

      Mock
      |> expect(:call, fn
        %{method: :get, url: "https://404.site/whatever"}, _opts ->
          {:ok, %Tesla.Env{status: 404, body: "Not found"}}
      end)

      assert capture_log([level: :warn], fn ->
               {:ok, _returned_activity, _entity} = Transmogrifier.handle_incoming(data)
             end) =~ "[warn] Parent object is something we don't handle"
    end

    test "it works for incoming notices" do
      data = File.read!("test/fixtures/mastodon-post-activity.json") |> Jason.decode!()

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

      assert data["id"] ==
               "https://framapiaf.org/users/admin/statuses/99512778738411822/activity"

      assert data["to"] == [
               "https://www.w3.org/ns/activitystreams#Public",
               "https://framapiaf.org/users/tcit"
             ]

      #      assert data["cc"] == [
      #               "https://framapiaf.org/users/admin/followers",
      #               "http://mobilizon.com/@tcit"
      #             ]

      assert data["actor"] == "https://framapiaf.org/users/admin"

      object = data["object"]
      assert object["id"] == "https://framapiaf.org/users/admin/statuses/99512778738411822"

      assert object["to"] == ["https://www.w3.org/ns/activitystreams#Public"]

      #      assert object["cc"] == [
      #               "https://framapiaf.org/users/admin/followers",
      #               "http://localtesting.pleroma.lol/users/lain"
      #             ]

      assert object["actor"] == "https://framapiaf.org/users/admin"
      assert object["attributedTo"] == "https://framapiaf.org/users/admin"

      {:ok, %Actor{}} = Actors.get_actor_by_url(object["actor"])
    end

    test "it works for incoming notices with hashtags" do
      data = File.read!("test/fixtures/mastodon-post-activity-hashtag.json") |> Jason.decode!()

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)
      assert Enum.at(data["object"]["tag"], 0)["name"] == "@tcit@framapiaf.org"
      assert Enum.at(data["object"]["tag"], 1)["name"] == "#moo"
    end

    test "it works for incoming notices with url not being a string (prismo)" do
      data = File.read!("test/fixtures/prismo-url-map.json") |> Jason.decode!()

      assert {:error, :not_supported} == Transmogrifier.handle_incoming(data)
      # Pages without groups are not supported
      # {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(data)

      # assert data["object"]["url"] == "https://prismo.news/posts/83"
    end
  end
end
