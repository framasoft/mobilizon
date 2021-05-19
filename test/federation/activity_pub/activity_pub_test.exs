# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/activity_pub/activity_pub_test.exs

defmodule Mobilizon.Federation.ActivityPubTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Mobilizon.DataCase

  import Mock
  import Mox
  import Mobilizon.Factory

  alias Mobilizon.{Discussions, Events}
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Todos.{Todo, TodoList}

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.HTTPSignatures.Signature
  alias Mobilizon.Service.HTTP.ActivityPub.Mock

  @activity_pub_public_audience "https://www.w3.org/ns/activitystreams#Public"

  describe "setting HTTP signature" do
    test "set http signature header" do
      actor = insert(:actor)

      signature =
        Signature.sign(actor, %{
          host: "example.com",
          "content-length": 15,
          digest: %{id: "my_id"} |> Jason.encode!() |> Signature.build_digest(),
          "(request-target)": Signature.generate_request_target("POST", "/inbox"),
          date: Signature.generate_date_header()
        })

      assert signature =~ "headers=\"(request-target) content-length date digest host\""
    end
  end

  describe "fetching an" do
    test "object by url" do
      url = "https://framapiaf.org/users/Framasoft/statuses/102093631881522097"

      data =
        File.read!("test/fixtures/mastodon-status-2.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{method: :get, url: ^url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}
      end)

      {:ok, object} = ActivityPub.fetch_object_from_url(url)

      {:ok, object_again} = ActivityPub.fetch_object_from_url(url)

      assert object.id == object_again.id
    end

    test "object reply by url" do
      url = "https://pirateradio.social/notice/A5XnLBsFNQDKtthzM0"
      reply_to_url = "https://framapiaf.org/users/peertube/statuses/105945857653893100"

      data =
        File.read!("test/fixtures/mastodon-status-3.json")
        |> Jason.decode!()

      reply_to_data =
        File.read!("test/fixtures/mastodon-status-4.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, 2, fn
        %{method: :get, url: ^url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}

        %{method: :get, url: ^reply_to_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: reply_to_data}}
      end)

      {:ok, object} = ActivityPub.fetch_object_from_url(url)

      assert object.in_reply_to_comment.url == reply_to_url
    end

    test "object reply to a video by url" do
      url = "https://diaspodon.fr/users/dada/statuses/100820008426311925"
      origin_url = "https://framatube.org/videos/watch/9c9de5e8-0a1e-484a-b099-e80766180a6d"

      data =
        File.read!("test/fixtures/mastodon-status-5.json")
        |> Jason.decode!()

      origin_data =
        File.read!("test/fixtures/peertube-video.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, 2, fn
        %{method: :get, url: ^url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}

        %{method: :get, url: ^origin_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: origin_data}}
      end)

      {:ok, object} = ActivityPub.fetch_object_from_url(url)

      assert object.in_reply_to_comment == nil
    end
  end

  describe "deletion" do
    test "it creates a delete activity and deletes the original event" do
      event = insert(:event)
      event = Events.get_public_event_by_url_with_preload!(event.url)
      {:ok, delete, _} = ActivityPub.delete(event, event.organizer_actor)

      assert delete.data["type"] == "Delete"
      assert delete.data["actor"] == event.organizer_actor.url
      assert delete.data["object"]["type"] == "Event"
      assert delete.data["object"]["id"] == event.url

      assert Events.get_event_by_url(event.url) == nil
    end

    test "it deletes the original event but only locally if needed" do
      with_mock Utils, [:passthrough],
        maybe_federate: fn _ -> :ok end,
        lazy_put_activity_defaults: fn args -> args end do
        event = insert(:event)
        event = Events.get_public_event_by_url_with_preload!(event.url)
        {:ok, delete, _} = ActivityPub.delete(event, event.organizer_actor, false)

        assert delete.data["type"] == "Delete"
        assert delete.data["actor"] == event.organizer_actor.url
        assert delete.data["object"]["type"] == "Event"
        assert delete.data["object"]["id"] == event.url
        assert delete.local == false

        assert Events.get_event_by_url(event.url) == nil

        assert_called(Utils.maybe_federate(delete))
      end
    end

    test "it creates a delete activity and deletes the original comment" do
      comment = insert(:comment)
      comment = Discussions.get_comment_from_url_with_preload!(comment.url)
      assert is_nil(Discussions.get_comment_from_url(comment.url).deleted_at)
      {:ok, delete, _} = ActivityPub.delete(comment, comment.actor)

      assert delete.data["type"] == "Delete"
      assert delete.data["actor"] == comment.actor.url
      assert delete.data["object"]["type"] == "Note"
      assert delete.data["object"]["id"] == comment.url

      refute is_nil(Discussions.get_comment_from_url(comment.url).deleted_at)
    end
  end

  describe "update" do
    @updated_actor_summary "This is an updated actor"

    test "it creates an update activity with the new actor data" do
      actor = insert(:actor)
      actor_data = %{summary: @updated_actor_summary}

      {:ok, update, _} = ActivityPub.update(actor, actor_data, false)

      assert update.data["actor"] == actor.url
      assert update.data["to"] == [@activity_pub_public_audience]
      assert update.data["object"]["id"] == actor.url
      assert update.data["object"]["type"] == :Person
      assert update.data["object"]["summary"] == @updated_actor_summary
    end

    @updated_start_time DateTime.utc_now() |> DateTime.truncate(:second)

    test "it creates an update activity with the new event data" do
      actor = insert(:actor)
      event = insert(:event, organizer_actor: actor)
      event_data = %{begins_on: @updated_start_time}

      {:ok, update, _} = ActivityPub.update(event, event_data)

      assert update.data["actor"] == actor.url
      assert update.data["to"] == [@activity_pub_public_audience]
      assert update.data["object"]["id"] == event.url
      assert update.data["object"]["type"] == "Event"
      assert update.data["object"]["startTime"] == DateTime.to_iso8601(@updated_start_time)
    end
  end

  describe "remove a member" do
    test "it creates an remove activity" do
      group = insert(:group)
      member = insert(:member, parent: group)
      moderator = insert(:actor)
      {:ok, activity, _member} = ActivityPub.remove(member, group, moderator, true)
      assert activity.data["type"] == "Remove"
      assert activity.data["actor"] == moderator.url
      assert activity.data["to"] == [group.members_url]
      assert activity.data["object"] == member.url
    end
  end

  describe "create a todo list" do
    @todo_list_title "My TODO-list"

    test "it creates a todo list" do
      with_mock Utils, [:passthrough], maybe_federate: fn _ -> :ok end do
        actor = insert(:actor)
        group = insert(:group)

        {:ok, create_data, %TodoList{url: todo_list_url}} =
          ActivityPub.create(:todo_list, %{title: @todo_list_title, actor_id: group.id}, true, %{
            "actor" => actor.url
          })

        assert create_data.local
        assert create_data.data["object"]["id"] == todo_list_url
        assert create_data.data["object"]["type"] == "TodoList"
        assert create_data.data["object"]["name"] == @todo_list_title
        assert create_data.data["to"] == [group.members_url]
        assert create_data.data["actor"] == actor.url

        assert_called(Utils.maybe_federate(create_data))
      end
    end
  end

  describe "create a todo" do
    @todo_title "Finish this thing"

    test "it creates a todo" do
      with_mock Utils, [:passthrough], maybe_federate: fn _ -> :ok end do
        actor = insert(:actor)
        todo_list = insert(:todo_list)

        {:ok, create_data, %Todo{url: todo_url}} =
          ActivityPub.create(
            :todo,
            %{title: @todo_title, todo_list_id: todo_list.id, creator_id: actor.id},
            true,
            %{"actor" => actor.url}
          )

        assert create_data.local
        assert create_data.data["object"]["id"] == todo_url
        assert create_data.data["object"]["type"] == "Todo"
        assert create_data.data["object"]["name"] == @todo_title
        assert create_data.data["to"] == [todo_list.actor.members_url]
        assert create_data.data["actor"] == actor.url

        assert_called(Utils.maybe_federate(create_data))
      end
    end
  end

  @resource_url "https://framasoft.org/fr/full"
  @resource_title "my resource"
  @updated_resource_title "my updated resource"
  @folder_title "my folder"
  describe "create resources" do
    test "it creates a resource" do
      with_mock Utils, [:passthrough], maybe_federate: fn _ -> :ok end do
        actor = insert(:actor)
        group = insert(:group)

        {:ok, create_data, %Resource{url: url}} =
          ActivityPub.create(
            :resource,
            %{
              title: @resource_title,
              creator_id: actor.id,
              actor_id: group.id,
              parent_id: nil,
              resource_url: @resource_url,
              type: :link
            },
            true
          )

        assert create_data.local
        assert create_data.data["type"] == "Create"
        assert create_data.data["object"]["id"] == url
        assert create_data.data["object"]["type"] == "Document"
        assert create_data.data["object"]["name"] == @resource_title

        assert create_data.data["object"]["url"] == @resource_url

        assert create_data.data["to"] == [group.members_url]
        assert create_data.data["actor"] == actor.url
        assert create_data.data["attributedTo"] == [actor.url]

        assert_called(Utils.maybe_federate(create_data))
      end
    end

    test "it creates a folder" do
      with_mock Utils, [:passthrough], maybe_federate: fn _ -> :ok end do
        actor = insert(:actor)
        group = insert(:group)

        {:ok, create_data, %Resource{url: url}} =
          ActivityPub.create(
            :resource,
            %{
              title: @folder_title,
              creator_id: actor.id,
              actor_id: group.id,
              parent_id: nil,
              type: :folder
            },
            true
          )

        assert create_data.local
        assert create_data.data["type"] == "Create"
        assert create_data.data["object"]["id"] == url
        assert create_data.data["object"]["type"] == "ResourceCollection"
        assert create_data.data["object"]["name"] == @folder_title
        assert create_data.data["to"] == [group.members_url]
        assert create_data.data["actor"] == actor.url
        assert create_data.data["attributedTo"] == [actor.url]

        assert_called(Utils.maybe_federate(create_data))
      end
    end

    test "it creates a resource in a folder" do
      with_mock Utils, [:passthrough], maybe_federate: fn _ -> :ok end do
        actor = insert(:actor)
        group = insert(:group)

        %Resource{id: parent_id, url: parent_url} =
          insert(:resource, type: :folder, resource_url: nil, actor: group)

        {:ok, create_data, %Resource{url: url}} =
          ActivityPub.create(
            :resource,
            %{
              title: @resource_title,
              creator_id: actor.id,
              actor_id: group.id,
              parent_id: parent_id,
              resource_url: @resource_url,
              type: :link
            },
            true
          )

        assert create_data.local
        assert create_data.data["type"] == "Add"
        assert create_data.data["target"] == parent_url
        assert create_data.data["object"]["id"] == url
        assert create_data.data["object"]["type"] == "Document"
        assert create_data.data["object"]["name"] == @resource_title

        assert create_data.data["object"]["url"] == @resource_url

        assert create_data.data["to"] == [group.members_url]
        assert create_data.data["actor"] == actor.url
        assert create_data.data["attributedTo"] == [actor.url]

        assert_called(Utils.maybe_federate(create_data))
      end
    end
  end

  describe "move resources" do
    test "rename resource" do
      with_mock Utils, [:passthrough], maybe_federate: fn _ -> :ok end do
        actor = insert(:actor)
        group = insert(:group)

        %Resource{} =
          resource =
          insert(:resource,
            resource_url: @resource_url,
            actor: group,
            creator: actor,
            title: @resource_title
          )

        {:ok, update_data, %Resource{url: url}} =
          ActivityPub.update(
            resource,
            %{
              title: @updated_resource_title
            },
            true
          )

        assert update_data.local
        assert update_data.data["type"] == "Update"
        assert update_data.data["object"]["id"] == url
        assert update_data.data["object"]["type"] == "Document"
        assert update_data.data["object"]["name"] == @updated_resource_title

        assert update_data.data["object"]["url"] == @resource_url

        assert update_data.data["to"] == [group.members_url]
        assert update_data.data["actor"] == actor.url
        assert update_data.data["attributedTo"] == [actor.url]

        assert_called(Utils.maybe_federate(update_data))
      end
    end

    test "move resource" do
      with_mock Utils, [:passthrough], maybe_federate: fn _ -> :ok end do
        actor = insert(:actor)
        group = insert(:group)

        %Resource{} =
          resource =
          insert(:resource,
            resource_url: @resource_url,
            actor: group,
            creator: actor,
            title: @resource_title
          )

        %Resource{id: parent_id, url: parent_url} =
          insert(:resource, type: :folder, resource_url: nil, actor: group)

        {:ok, update_data, %Resource{url: url}} =
          ActivityPub.move(
            :resource,
            resource,
            %{
              parent_id: parent_id
            },
            true
          )

        assert update_data.local
        assert update_data.data["type"] == "Move"
        assert update_data.data["object"]["id"] == url
        assert update_data.data["object"]["type"] == "Document"
        assert update_data.data["object"]["name"] == @resource_title

        assert update_data.data["object"]["url"] == @resource_url

        assert update_data.data["to"] == [group.members_url]
        assert update_data.data["actor"] == actor.url
        assert update_data.data["origin"] == nil
        assert update_data.data["target"] == parent_url

        assert_called(Utils.maybe_federate(update_data))
      end
    end
  end

  describe "delete resources" do
    test "delete resource" do
      with_mock Utils, [:passthrough], maybe_federate: fn _ -> :ok end do
        actor = insert(:actor)
        group = insert(:group)

        %Resource{} =
          resource =
          insert(:resource,
            resource_url: @resource_url,
            actor: group,
            creator: actor,
            title: @resource_title
          )

        {:ok, update_data, %Resource{url: url}} =
          ActivityPub.delete(
            resource,
            actor,
            true
          )

        assert update_data.local
        assert update_data.data["type"] == "Delete"
        assert update_data.data["object"]["type"] == "Document"
        assert update_data.data["object"]["id"] == url
        assert update_data.data["to"] == [group.members_url]
        assert update_data.data["actor"] == actor.url
        assert update_data.data["attributedTo"] == [group.url]

        assert_called(Utils.maybe_federate(update_data))
      end
    end
  end

  describe "announce" do
  end
end
