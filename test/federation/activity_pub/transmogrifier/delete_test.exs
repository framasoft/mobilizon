defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.DeleteTest do
  use Mobilizon.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Oban.Testing, repo: Mobilizon.Storage.Repo
  import Mobilizon.Factory
  import Mox

  alias Mobilizon.{Actors, Discussions, Events, Posts, Resources}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Federation.ActivityPub.{Activity, Transmogrifier}
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Service.HTTP.ActivityPub.Mock

  describe "handle incoming delete activities" do
    test "it works for incoming deletes" do
      %Actor{url: actor_url} =
        actor = insert(:actor, url: "http://mobilizon.tld/@remote", domain: "mobilizon.tld")

      %Comment{url: comment_url} =
        insert(:comment,
          actor: nil,
          actor_id: actor.id,
          url: "http://mobilizon.tld/comments/9f3794b8-11a0-4a98-8cb7-475ab332c701"
        )

      Mock
      |> expect(:call, fn
        %{method: :get, url: "http://mobilizon.tld/comments/9f3794b8-11a0-4a98-8cb7-475ab332c701"},
        _opts ->
          {:ok, %Tesla.Env{status: 410, body: "Gone"}}
      end)

      data =
        File.read!("test/fixtures/mastodon-delete.json")
        |> Jason.decode!()

      object =
        data["object"]
        |> Map.put("id", comment_url)

      data =
        data
        |> Map.put("object", object)
        |> Map.put("actor", actor_url)

      assert Discussions.get_comment_from_url(comment_url)
      assert is_nil(Discussions.get_comment_from_url(comment_url).deleted_at)

      {:ok, %Activity{local: false}, _} = Transmogrifier.handle_incoming(data)

      refute is_nil(Discussions.get_comment_from_url(comment_url).deleted_at)
    end

    test "it fails for incoming deletes with spoofed origin" do
      comment = insert(:comment)

      announce_data =
        File.read!("test/fixtures/mastodon-announce.json")
        |> Jason.decode!()
        |> Map.put("object", comment.url)

      {:ok, _, _} = Transmogrifier.handle_incoming(announce_data)

      data =
        File.read!("test/fixtures/mastodon-delete.json")
        |> Jason.decode!()

      object =
        data["object"]
        |> Map.put("id", comment.url)

      data =
        data
        |> Map.put("object", object)

      {:error, :unknown_actor} = Transmogrifier.handle_incoming(data)

      assert Discussions.get_comment_from_url(comment.url)
    end

    setup :set_mox_from_context

    test "it works for incoming actor deletes" do
      %Actor{url: url} =
        actor = insert(:actor, url: "https://framapiaf.org/users/admin", domain: "framapiaf.org")

      %Event{url: event1_url} = event1 = insert(:event, organizer_actor: actor)
      insert(:event, organizer_actor: actor)

      %Comment{url: comment1_url} = comment1 = insert(:comment, actor: actor)
      insert(:comment, actor: actor)

      data =
        File.read!("test/fixtures/mastodon-delete-user.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{method: :get, url: "https://framapiaf.org/users/admin"}, _opts ->
          {:ok, %Tesla.Env{status: 410, body: "Gone"}}
      end)

      {:ok, _activity, _actor} = Transmogrifier.handle_incoming(data)
      assert %{success: 1, failure: 0} == Oban.drain_queue(queue: :background)

      assert {:error, :actor_not_found} = Actors.get_actor_by_url(url)
      assert {:error, :event_not_found} = Events.get_event(event1.id)
      # Tombstone are cascade deleted, seems correct for now
      # assert %Tombstone{} = Tombstone.find_tombstone(event1_url)
      assert %Comment{deleted_at: deleted_at} = Discussions.get_comment(comment1.id)
      refute is_nil(deleted_at)
      # assert %Tombstone{} = Tombstone.find_tombstone(comment1_url)
    end

    test "it fails for incoming actor deletes with spoofed origin" do
      %{url: url} = insert(:actor)

      data =
        File.read!("test/fixtures/mastodon-delete-user.json")
        |> Jason.decode!()
        |> Map.put("actor", url)

      deleted_actor_url = "https://framapiaf.org/users/admin"

      deleted_actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()
        |> Map.put("id", deleted_actor_url)

      Mock
      |> expect(:call, fn
        %{url: ^deleted_actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: deleted_actor_data}}
      end)

      assert :error == Transmogrifier.handle_incoming(data)

      assert Actors.get_actor_by_url(url)
    end
  end

  describe "handle incoming delete activities for group posts" do
    test "works for remote deletions by moderators" do
      %Actor{url: remote_actor_url} =
        remote_actor =
        insert(:actor,
          domain: "remote.domain",
          url: "https://remote.domain/@remote",
          preferred_username: "remote"
        )

      group = insert(:group)
      insert(:member, actor: remote_actor, parent: group, role: :moderator)
      %Post{} = post = insert(:post, attributed_to: group)

      data = Convertible.model_to_as(post)
      refute is_nil(Posts.get_post_by_url(data["id"]))

      delete_data =
        File.read!("test/fixtures/mastodon-delete.json")
        |> Jason.decode!()

      object =
        data
        |> Map.put("type", "Article")

      delete_data =
        delete_data
        |> Map.put("actor", remote_actor_url)
        |> Map.put("object", object)

      {:ok, _activity, _actor} = Transmogrifier.handle_incoming(delete_data)

      assert is_nil(Posts.get_post_by_url(data["id"]))
    end

    test "doesn't work for remote deletions if the actor is just a group member" do
      %Actor{url: remote_actor_url} =
        remote_actor =
        insert(:actor,
          domain: "remote.domain",
          url: "https://remote.domain/@remote",
          preferred_username: "remote"
        )

      group = insert(:group)
      insert(:member, actor: remote_actor, parent: group, role: :member)
      %Post{} = post = insert(:post, attributed_to: group)

      data = Convertible.model_to_as(post)
      refute is_nil(Posts.get_post_by_url(data["id"]))

      delete_data =
        File.read!("test/fixtures/mastodon-delete.json")
        |> Jason.decode!()

      object =
        data
        |> Map.put("type", "Article")

      delete_data =
        delete_data
        |> Map.put("actor", remote_actor_url)
        |> Map.put("object", object)

      :error = Transmogrifier.handle_incoming(delete_data)

      refute is_nil(Posts.get_post_by_url(data["id"]))
    end

    test "doesn't work for remote deletions if the actor is not a group member" do
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

      delete_data =
        File.read!("test/fixtures/mastodon-delete.json")
        |> Jason.decode!()

      object =
        data
        |> Map.put("type", "Article")

      delete_data =
        delete_data
        |> Map.put("actor", remote_actor_url)
        |> Map.put("object", object)

      :error = Transmogrifier.handle_incoming(delete_data)

      refute is_nil(Posts.get_post_by_url(data["id"]))
    end
  end

  describe "handle incoming delete activities for resources" do
    test "works for remote deletions" do
      %Actor{url: remote_actor_url} =
        remote_actor =
        insert(:actor,
          domain: "remote.domain",
          url: "http://remote.domain/@remote",
          preferred_username: "remote"
        )

      group = insert(:group)
      insert(:member, actor: remote_actor, parent: group, role: :member)
      %Resource{} = resource = insert(:resource, actor: group)

      data = Convertible.model_to_as(resource)
      refute is_nil(Resources.get_resource_by_url(data["id"]))

      delete_data =
        File.read!("test/fixtures/mastodon-delete.json")
        |> Jason.decode!()

      object =
        data
        |> Map.put("type", "Document")

      delete_data =
        delete_data
        |> Map.put("actor", remote_actor_url)
        |> Map.put("object", object)

      {:ok, _activity, _actor} = Transmogrifier.handle_incoming(delete_data)

      assert is_nil(Resources.get_resource_by_url(data["id"]))
    end

    test "doesn't work for remote deletions if the actor is not a group member" do
      %Actor{url: remote_actor_url} =
        insert(:actor,
          domain: "remote.domain",
          url: "http://remote.domain/@remote",
          preferred_username: "remote"
        )

      group = insert(:group)
      %Post{} = post = insert(:post, attributed_to: group)

      data = Convertible.model_to_as(post)
      refute is_nil(Posts.get_post_by_url(data["id"]))

      delete_data =
        File.read!("test/fixtures/mastodon-delete.json")
        |> Jason.decode!()

      object =
        data
        |> Map.put("type", "Article")

      delete_data =
        delete_data
        |> Map.put("actor", remote_actor_url)
        |> Map.put("object", object)

      :error = Transmogrifier.handle_incoming(delete_data)

      refute is_nil(Posts.get_post_by_url(data["id"]))
    end
  end
end
