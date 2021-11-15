defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.UpdateTest do
  use Mobilizon.DataCase
  use Oban.Testing, repo: Mobilizon.Storage.Repo
  import Mobilizon.Factory
  import Mox

  alias Mobilizon.{Actors, Events, Posts}
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Federation.ActivityPub.{Activity, Transmogrifier}
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Service.HTTP.ActivityPub.Mock

  describe "handle incoming update activities" do
    test "it works for incoming update activities on actors" do
      data = File.read!("test/fixtures/mastodon-post-activity.json") |> Jason.decode!()

      actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, 2, fn
        %{method: :get, url: "https://framapiaf.org/users/admin"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}

        %{method: :get, url: "https://framapiaf.org/users/tcit"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}
      end)

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)
      update_data = File.read!("test/fixtures/mastodon-update.json") |> Jason.decode!()

      object =
        update_data["object"]
        |> Map.put("actor", data["actor"])
        |> Map.put("id", data["actor"])

      update_data =
        update_data
        |> Map.put("actor", data["actor"])
        |> Map.put("object", object)

      {:ok, %Activity{data: _data, local: false}, _} = Transmogrifier.handle_incoming(update_data)

      {:ok, %Actor{} = actor} = Actors.get_actor_by_url(update_data["actor"])
      assert actor.name == "nextsoft"

      assert actor.summary == "<p>Some bio</p>"
    end

    test "it works for incoming update activities on events" do
      data = File.read!("test/fixtures/mobilizon-post-activity.json") |> Jason.decode!()

      actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, 2, fn
        %{method: :get, url: "https://mobilizon.fr/@metacartes"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}

        %{method: :get, url: "https://framapiaf.org/users/tcit"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}
      end)

      {:ok, %Activity{data: data, local: false}, %Event{id: event_id}} =
        Transmogrifier.handle_incoming(data)

      assert_enqueued(
        worker: Mobilizon.Service.Workers.BuildSearch,
        args: %{event_id: event_id, op: :insert_search_event}
      )

      assert %{success: 1, snoozed: 0, failure: 0} == Oban.drain_queue(queue: :search)

      update_data = File.read!("test/fixtures/mastodon-update.json") |> Jason.decode!()

      object =
        data["object"]
        |> Map.put("actor", data["actor"])
        |> Map.put("name", "My updated event")
        |> Map.put("id", data["object"]["id"])
        |> Map.put("type", "Event")

      update_data =
        update_data
        |> Map.put("actor", data["actor"])
        |> Map.put("object", object)

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(update_data)

      %Event{} = event = Events.get_event_by_url(data["object"]["id"])

      assert_enqueued(
        worker: Mobilizon.Service.Workers.BuildSearch,
        args: %{event_id: event_id, op: :update_search_event}
      )

      assert %{success: 1, snoozed: 0, failure: 0} == Oban.drain_queue(queue: :search)

      assert event.title == "My updated event"

      assert event.description == data["object"]["content"]
    end

    #     test "it works for incoming update activities which lock the account" do
    #       data = File.read!("test/fixtures/mastodon-post-activity.json") |> Jason.decode!()

    #       {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(data)
    #       update_data = File.read!("test/fixtures/mastodon-update.json") |> Jason.decode!()

    #       object =
    #         update_data["object"]
    #         |> Map.put("actor", data["actor"])
    #         |> Map.put("id", data["actor"])
    #         |> Map.put("manuallyApprovesFollowers", true)

    #       update_data =
    #         update_data
    #         |> Map.put("actor", data["actor"])
    #         |> Map.put("object", object)

    #       {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(update_data)

    #       user = User.get_cached_by_ap_id(data["actor"])
    #       assert user.info["locked"] == true
    #     end
  end

  describe "handle incoming updates activities for group posts" do
    test "it works for incoming update activities on group posts when remote actor is a moderator" do
      %Actor{url: remote_actor_url} =
        remote_actor =
        insert(:actor,
          domain: "remote.domain",
          url: "https://remote.domain/@remote",
          preferred_username: "remote"
        )

      group = insert(:group)
      %Member{} = _member = insert(:member, actor: remote_actor, parent: group, role: :moderator)
      %Post{} = post = insert(:post, attributed_to: group)

      data = Convertible.model_to_as(post)
      refute is_nil(Posts.get_post_by_url(data["id"]))

      update_data = File.read!("test/fixtures/mastodon-update.json") |> Jason.decode!()

      object =
        data
        |> Map.put("name", "My updated post")
        |> Map.put("type", "Article")

      update_data =
        update_data
        |> Map.put("actor", remote_actor_url)
        |> Map.put("object", object)

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(update_data)

      %Post{id: updated_post_id, title: updated_post_title} =
        Posts.get_post_by_url(data["object"]["id"])

      assert updated_post_id == post.id
      assert updated_post_title == "My updated post"
    end

    test "it works for incoming update activities on group posts" do
      %Actor{url: remote_actor_url} =
        remote_actor =
        insert(:actor,
          domain: "remote.domain",
          url: "https://remote.domain/@remote",
          preferred_username: "remote"
        )

      group = insert(:group)
      %Member{} = _member = insert(:member, actor: remote_actor, parent: group)
      %Post{} = post = insert(:post, attributed_to: group)

      data = Convertible.model_to_as(post)
      refute is_nil(Posts.get_post_by_url(data["id"]))

      update_data = File.read!("test/fixtures/mastodon-update.json") |> Jason.decode!()

      object =
        data
        |> Map.put("name", "My updated post")
        |> Map.put("type", "Article")

      update_data =
        update_data
        |> Map.put("actor", remote_actor_url)
        |> Map.put("object", object)

      :error = Transmogrifier.handle_incoming(update_data)

      %Post{id: updated_post_id, title: updated_post_title} = Posts.get_post_by_url(data["id"])

      assert updated_post_id == post.id
      refute updated_post_title == "My updated post"
    end

    test "it fails for incoming update activities on group posts when the actor is not a member from the group" do
      %Actor{url: remote_actor_url} =
        insert(:actor,
          domain: "remote.domain",
          url: "https://remote.domain/@remote",
          preferred_username: "remote"
        )

      group = insert(:group)
      %Post{} = post = insert(:post, attributed_to: group)

      data = Convertible.model_to_as(post)
      refute is_nil(Posts.get_post_by_url(data["id"]))

      update_data = File.read!("test/fixtures/mastodon-update.json") |> Jason.decode!()

      object =
        data
        |> Map.put("name", "My updated post")
        |> Map.put("type", "Article")

      update_data =
        update_data
        |> Map.put("actor", remote_actor_url)
        |> Map.put("object", object)

      :error = Transmogrifier.handle_incoming(update_data)

      %Post{id: updated_post_id, title: updated_post_title} = Posts.get_post_by_url(data["id"])

      assert updated_post_id == post.id
      refute updated_post_title == "My updated post"
    end
  end
end
