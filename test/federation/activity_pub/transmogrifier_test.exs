# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/activity_pub/transmogrifier_test.exs

defmodule Mobilizon.Federation.ActivityPub.TransmogrifierTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Mobilizon.DataCase
  use Oban.Testing, repo: Mobilizon.Storage.Repo

  import Mobilizon.Factory
  import ExUnit.CaptureLog
  import Mock
  import Mox

  alias Mobilizon.{Actors, Discussions, Events}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Todos.{Todo, TodoList}

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityPub.{Activity, Relay, Transmogrifier}
  alias Mobilizon.Federation.ActivityStream.Convertible

  alias Mobilizon.GraphQL.API
  alias Mobilizon.Service.HTTP.ActivityPub.Mock
  alias Mobilizon.Tombstone
  alias Mobilizon.Web.Endpoint

  describe "handle incoming events" do
    test "it works for incoming events" do
      use_cassette "activity_pub/fetch_mobilizon_post_activity" do
        data = File.read!("test/fixtures/mobilizon-post-activity.json") |> Jason.decode!()

        {:ok, %Activity{data: data, local: false}, %Event{} = event} =
          Transmogrifier.handle_incoming(data)

        assert data["id"] ==
                 "https://test.mobilizon.org/events/39026210-0c69-4238-b3cc-986f33f98ed0/activity"

        assert data["to"] == ["https://www.w3.org/ns/activitystreams#Public"]

        #
        #      assert data["cc"] == [
        #               "https://framapiaf.org/users/admin/followers",
        #               "http://localtesting.pleroma.lol/users/lain"
        #             ]

        assert data["actor"] == "https://test.mobilizon.org/@Alicia"

        object = data["object"]

        assert object["id"] ==
                 "https://test.mobilizon.org/events/39026210-0c69-4238-b3cc-986f33f98ed0"

        assert object["to"] == ["https://www.w3.org/ns/activitystreams#Public"]

        #      assert object["cc"] == [
        #               "https://framapiaf.org/users/admin/followers",
        #               "http://localtesting.pleroma.lol/users/lain"
        #             ]

        assert object["actor"] == "https://test.mobilizon.org/@Alicia"
        assert object["location"]["name"] == "Locaux de Framasoft"
        # assert object["attributedTo"] == "https://test.mobilizon.org/@Alicia"

        assert event.physical_address.street == "10 Rue Jangot"

        assert event.physical_address.url ==
                 "https://event1.tcit.fr/address/eeecc11d-0030-43e8-a897-6422876372jd"

        assert event.online_address == "https://google.com"

        {:ok, %Actor{}} = Actors.get_actor_by_url(object["actor"])
      end
    end

    test "it works for incoming events for local groups" do
      %Actor{url: group_url, id: group_id} = group = insert(:group)

      %Actor{url: actor_url, id: actor_id} =
        actor =
        insert(:actor,
          domain: "test.mobilizon.org",
          url: "https://test.mobilizon.org/@member",
          preferred_username: "member"
        )

      with_mock ActivityPub, [:passthrough],
        get_or_fetch_actor_by_url: fn url ->
          case url do
            ^group_url -> {:ok, group}
            ^actor_url -> {:ok, actor}
          end
        end do
        data = File.read!("test/fixtures/mobilizon-post-activity-group.json") |> Jason.decode!()

        object =
          data["object"] |> Map.put("actor", actor_url) |> Map.put("attributedTo", group_url)

        data =
          data
          |> Map.put("actor", actor_url)
          |> Map.put("attributedTo", group_url)
          |> Map.put("object", object)

        assert {:ok, %Activity{data: activity_data, local: false}, %Event{} = event} =
                 Transmogrifier.handle_incoming(data)

        assert event.organizer_actor_id == actor_id
        assert event.attributed_to_id == group_id
        assert activity_data["actor"] == actor_url
        assert activity_data["attributedTo"] == group_url
        assert activity_data["object"]["actor"] == actor_url
        assert activity_data["object"]["attributedTo"] == group_url
      end
    end
  end

  describe "handle incoming todo lists" do
    test "it ignores an incoming todo list if we already have it" do
      todo_list = insert(:todo_list)
      actor = insert(:actor)

      activity = %{
        "type" => "Create",
        "to" => ["https://www.w3.org/ns/activitystreams#Public"],
        "actor" => actor.url,
        "object" => Convertible.model_to_as(todo_list)
      }

      data =
        File.read!("test/fixtures/mastodon-post-activity.json")
        |> Jason.decode!()
        |> Map.put("object", activity["object"])

      assert {:ok, nil, _} = Transmogrifier.handle_incoming(data)
    end

    test "it accepts incoming todo lists" do
      actor = insert(:actor)
      group = insert(:group, domain: "morebilizon.com")

      activity = %{
        "type" => "Create",
        "to" => ["https://www.w3.org/ns/activitystreams#Public"],
        "actor" => actor.url,
        "object" => %{
          "type" => "TodoList",
          "actor" => group.url,
          "id" => "https://mobilizon.app/todo-list/gjfkghfkd",
          "name" => "My new todo list"
        }
      }

      assert {:ok, %Activity{data: data, local: false}, %TodoList{}} =
               Transmogrifier.handle_incoming(activity)

      assert data["actor"] == actor.url
      assert data["object"]["actor"] == group.url
    end

    @mobilizon_group_url "https://mobilizon.app/@mygroupe"
    test "it accepts incoming todo lists and fetches the group if needed" do
      group = insert(:group, domain: "morebilizon.com", url: @mobilizon_group_url)
      %Actor{url: actor_url} = actor = insert(:actor)

      with_mock ActivityPub, [:passthrough],
        get_or_fetch_actor_by_url: fn url ->
          case url do
            @mobilizon_group_url -> {:ok, group}
            actor_url -> {:ok, actor}
          end
        end do
        activity = %{
          "type" => "Create",
          "to" => ["https://www.w3.org/ns/activitystreams#Public"],
          "actor" => actor.url,
          "object" => %{
            "type" => "TodoList",
            "actor" => @mobilizon_group_url,
            "id" => "https://mobilizon.app/todo-list/gjfkghfkd",
            "name" => "My new todo list"
          }
        }

        assert {:ok, %Activity{data: data, local: false}, %TodoList{}} =
                 Transmogrifier.handle_incoming(activity)

        assert data["actor"] == actor.url
        assert data["object"]["actor"] == @mobilizon_group_url
      end
    end

    test "it accepts incoming todo lists and handles group being not found" do
      %Actor{url: actor_url} = actor = insert(:actor)

      with_mock ActivityPub, [:passthrough],
        get_or_fetch_actor_by_url: fn url ->
          case url do
            @mobilizon_group_url -> {:error, "Not found"}
            ^actor_url -> {:ok, actor}
          end
        end do
        activity = %{
          "type" => "Create",
          "to" => ["https://www.w3.org/ns/activitystreams#Public"],
          "actor" => actor_url,
          "object" => %{
            "type" => "TodoList",
            "actor" => @mobilizon_group_url,
            "id" => "https://mobilizon.app/todo-list/gjfkghfkd",
            "name" => "My new todo list"
          }
        }

        assert :error = Transmogrifier.handle_incoming(activity)
      end
    end
  end

  describe "handle incoming todos" do
    test "it ignores an incoming todo if we already have it" do
      todo = insert(:todo)
      actor = insert(:actor)

      activity = %{
        "type" => "Create",
        "to" => ["https://www.w3.org/ns/activitystreams#Public"],
        "actor" => actor.url,
        "object" => Convertible.model_to_as(todo)
      }

      data =
        File.read!("test/fixtures/mastodon-post-activity.json")
        |> Jason.decode!()
        |> Map.put("object", activity["object"])

      assert {:ok, nil, _} = Transmogrifier.handle_incoming(data)
    end

    test "it accepts incoming todos" do
      actor = insert(:actor)
      todo_list = insert(:todo_list)

      activity = %{
        "type" => "Create",
        "to" => ["https://www.w3.org/ns/activitystreams#Public"],
        "actor" => actor.url,
        "object" => %{
          "type" => "Todo",
          "actor" => actor.url,
          "todoList" => todo_list.url,
          "id" => "https://mobilizon.app/todo/gjfkghfkd",
          "name" => "My new todo",
          "status" => false
        }
      }

      assert {:ok, %Activity{data: data, local: false},
              %Todo{todo_list: %TodoList{id: todo_list_id}}} =
               Transmogrifier.handle_incoming(activity)

      assert data["actor"] == actor.url
      assert data["object"]["todoList"] == todo_list.url
      assert todo_list_id == todo_list.id
    end

    @mobilizon_group_url "https://mobilizon.app/@mygroupe"
    test "it accepts incoming todos and fetches the todo list if needed" do
      group = insert(:group, domain: "morebilizon.com", url: @mobilizon_group_url)
      %Actor{url: actor_url} = actor = insert(:actor)

      with_mock ActivityPub, [:passthrough],
        get_or_fetch_actor_by_url: fn url ->
          case url do
            @mobilizon_group_url -> {:ok, group}
            actor_url -> {:ok, actor}
          end
        end do
        activity = %{
          "type" => "Create",
          "to" => ["https://www.w3.org/ns/activitystreams#Public"],
          "actor" => actor.url,
          "object" => %{
            "type" => "TodoList",
            "actor" => @mobilizon_group_url,
            "id" => "https://mobilizon.app/todo-list/gjfkghfkd",
            "name" => "My new todo list"
          }
        }

        assert {:ok, %Activity{data: data, local: false}, %TodoList{}} =
                 Transmogrifier.handle_incoming(activity)

        assert data["actor"] == actor.url
        assert data["object"]["actor"] == @mobilizon_group_url
      end
    end

    test "it accepts incoming todo lists and handles group being not found" do
      %Actor{url: actor_url} = actor = insert(:actor)

      with_mock ActivityPub, [:passthrough],
        get_or_fetch_actor_by_url: fn url ->
          case url do
            @mobilizon_group_url -> {:error, "Not found"}
            ^actor_url -> {:ok, actor}
          end
        end do
        activity = %{
          "type" => "Create",
          "to" => ["https://www.w3.org/ns/activitystreams#Public"],
          "actor" => actor_url,
          "object" => %{
            "type" => "TodoList",
            "actor" => @mobilizon_group_url,
            "id" => "https://mobilizon.app/todo-list/gjfkghfkd",
            "name" => "My new todo list"
          }
        }

        assert :error = Transmogrifier.handle_incoming(activity)
      end
    end
  end

  describe "handle incoming resources" do
    test "it ignores an incoming resource if we already have it" do
      actor = insert(:actor)
      group = insert(:group)
      %Resource{} = resource = insert(:resource, actor: group, creator: actor)

      activity = %{
        "type" => "Add",
        "to" => [group.members_url],
        "actor" => actor.url,
        "target" => group.resources_url,
        "object" => Convertible.model_to_as(resource)
      }

      assert {:ok, nil, _} = Transmogrifier.handle_incoming(activity)
    end

    test "it accepts incoming resources" do
      creator =
        insert(:actor,
          domain: "mobilizon.app",
          url: "https://mobilizon.app/@myremoteactor",
          preferred_username: "myremoteactor"
        )

      group =
        insert(:group,
          domain: "somewhere.com",
          url: "https://somewhere.com/@myremotegroup",
          preferred_username: "myremotegroup"
        )

      insert(:member, parent: group, actor: creator, role: :member)

      activity = %{
        "type" => "Add",
        "to" => [group.members_url],
        "actor" => creator.url,
        "target" => group.resources_url,
        "object" => %{
          "type" => "Document",
          "actor" => creator.url,
          "attributedTo" => [group.url],
          "id" => "https://mobilizon.app/resource/gjfkghfkd",
          "name" => "My new resource",
          "summary" => "A description for the resource",
          "url" => "https://framasoft.org"
        }
      }

      assert {:ok, %Activity{data: data, local: false}, %Resource{} = resource} =
               Transmogrifier.handle_incoming(activity)

      assert resource.actor_id == group.id
      assert resource.creator_id == creator.id
      assert resource.title == "My new resource"
      assert resource.type == :link
      assert is_nil(resource.parent_id)
    end

    test "it accepts incoming folders" do
      creator =
        insert(:actor,
          domain: "mobilizon.app",
          url: "https://mobilizon.app/@myremoteactor",
          preferred_username: "myremoteactor"
        )

      group =
        insert(:group,
          domain: "somewhere.com",
          url: "https://somewhere.com/@myremotegroup",
          preferred_username: "myremotegroup"
        )

      insert(:member, parent: group, actor: creator, role: :member)

      activity = %{
        "type" => "Add",
        "to" => [group.members_url],
        "actor" => creator.url,
        "target" => group.resources_url,
        "object" => %{
          "type" => "ResourceCollection",
          "actor" => creator.url,
          "attributedTo" => [group.url],
          "id" => "https://mobilizon.app/resource/gjfkghfkd",
          "name" => "My new folder"
        }
      }

      assert {:ok, %Activity{data: data, local: false}, %Resource{} = resource} =
               Transmogrifier.handle_incoming(activity)

      assert resource.actor_id == group.id
      assert resource.creator_id == creator.id
      assert resource.title == "My new folder"
      assert resource.type == :folder
      assert is_nil(resource.parent_id)
    end

    test "it accepts incoming resources that are in a folder" do
      creator =
        insert(:actor,
          domain: "mobilizon1.com",
          url: "http://mobilizon1.com/@tcit",
          preferred_username: "tcit",
          user: nil
        )

      group =
        insert(:group,
          domain: "mobilizon1.com",
          url: "http://mobilizon1.com/@demo",
          preferred_username: "demo",
          resources_url: "http://mobilizon1.com/@demo/resources"
        )

      insert(:member, parent: group, actor: creator, role: :member)

      parent_resource =
        insert(:resource,
          type: :folder,
          title: "folder",
          path: "/folder",
          actor: group,
          creator: creator
        )

      activity = %{
        "type" => "Add",
        "to" => [group.members_url],
        "actor" => creator.url,
        "target" => parent_resource.url,
        "object" => %{
          "type" => "Document",
          "actor" => creator.url,
          "attributedTo" => [group.url],
          "id" => "https://mobilizon.app/resource/gjfkghfkd",
          "name" => "My new resource",
          "summary" => "A description for the resource",
          "context" => parent_resource.url,
          "url" => "https://framasoft.org"
        }
      }

      assert {:ok, %Activity{data: data, local: false}, %Resource{} = resource} =
               Transmogrifier.handle_incoming(activity)

      assert resource.actor_id == group.id
      assert resource.creator_id == creator.id
      assert resource.title == "My new resource"
      assert resource.type == :link
      refute is_nil(resource.parent_id)
      assert resource.parent_id == parent_resource.id
    end

    test "it accepts incoming resources and handles group being not found" do
      creator =
        insert(:actor,
          domain: "mobilizon.app",
          url: "https://mobilizon.app/@myremoteactor",
          preferred_username: "myremoteactor"
        )

      group =
        insert(:group,
          domain: "somewhere.com",
          url: "https://somewhere.com/@myremotegroup",
          preferred_username: "myremotegroup"
        )

      insert(:member, parent: group, actor: creator, role: :member)

      activity = %{
        "type" => "Add",
        "to" => [group.members_url],
        "actor" => creator.url,
        "target" => group.resources_url,
        "object" => %{
          "type" => "Document",
          "actor" => "https://someurl.com/notfound",
          "attributedTo" => "https://someurl.com/notfound",
          "id" => "https://mobilizon.app/resource/gjfkghfkd",
          "name" => "My new resource",
          "summary" => "A description for the resource",
          "url" => "https://framasoft.org"
        }
      }

      assert :error = Transmogrifier.handle_incoming(activity)
    end

    test "it refuses incoming resources if actor is not a member of the group" do
      creator =
        insert(:actor,
          domain: "mobilizon.app",
          url: "https://mobilizon.app/@myremoteactor",
          preferred_username: "myremoteactor"
        )

      group =
        insert(:group,
          domain: "somewhere.com",
          url: "https://somewhere.com/@myremotegroup",
          preferred_username: "myremotegroup"
        )

      activity = %{
        "type" => "Add",
        "to" => [group.members_url],
        "actor" => creator.url,
        "target" => group.resources_url,
        "object" => %{
          "type" => "Document",
          "actor" => creator.url,
          "attributedTo" => [group.url],
          "id" => "https://mobilizon.app/resource/gjfkghfkd",
          "name" => "My new resource",
          "summary" => "A description for the resource",
          "url" => "https://framasoft.org"
        }
      }

      assert :error = Transmogrifier.handle_incoming(activity)
    end
  end

  describe "handle incoming follow requests" do
    test "it works for incoming follow requests" do
      use_cassette "activity_pub/mastodon_follow_activity" do
        actor = insert(:actor)

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
    end

    test "it rejects activities without a valid ID" do
      actor = insert(:actor)

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

  # test "it works for incoming likes" do
  #   %Comment{url: url} = insert(:comment)

  #   data =
  #     File.read!("test/fixtures/mastodon-like.json")
  #     |> Jason.decode!()
  #     |> Map.put("object", url)

  #   {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(data)

  #   assert data["actor"] == "http://mastodon.example.org/users/admin"
  #   assert data["type"] == "Like"
  #   assert data["id"] == "http://mastodon.example.org/users/admin#likes/2"
  #   assert data["object"] == url
  # end

  # test "it returns an error for incoming unlikes wihout a like activity" do
  #   %Comment{url: url} = insert(:comment)

  #   data =
  #     File.read!("test/fixtures/mastodon-undo-like.json")
  #     |> Jason.decode!()
  #     |> Map.put("object", url)

  #   assert Transmogrifier.handle_incoming(data) == {:error, :not_supported}
  # end

  # test "it works for incoming unlikes with an existing like activity" do
  #   comment = insert(:comment)

  #   like_data =
  #     File.read!("test/fixtures/mastodon-like.json")
  #     |> Jason.decode!()
  #     |> Map.put("object", comment.url)

  #   {:ok, %Activity{data: like_data, local: false}} = Transmogrifier.handle_incoming(like_data)

  #   data =
  #     File.read!("test/fixtures/mastodon-undo-like.json")
  #     |> Jason.decode!()
  #     |> Map.put("object", like_data)
  #     |> Map.put("actor", like_data["actor"])

  #   {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(data)

  #   assert data["actor"] == "http://mastodon.example.org/users/admin"
  #   assert data["type"] == "Undo"
  #   assert data["id"] == "http://mastodon.example.org/users/admin#likes/2/undo"
  #   assert data["object"]["id"] == "http://mastodon.example.org/users/admin#likes/2"
  # end

  describe "handle incoming follow announces" do
    test "it works for incoming announces" do
      data = File.read!("test/fixtures/mastodon-announce.json") |> Jason.decode!()
      status_data = File.read!("test/fixtures/mastodon-status.json") |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{method: :get, url: "https://framapiaf.org/users/peertube/statuses/104584600044284729"},
        _opts ->
          {:ok, %Tesla.Env{status: 200, body: status_data}}
      end)

      {:ok, _, %Comment{actor: %Actor{url: actor_url}, url: comment_url}} =
        Transmogrifier.handle_incoming(data)

      assert actor_url == "https://framapiaf.org/users/peertube"

      assert comment_url ==
               "https://framapiaf.org/users/peertube/statuses/104584600044284729"
    end

    test "it works for incoming announces with an existing activity" do
      %Comment{url: comment_url, actor: %Actor{url: actor_url} = actor} = insert(:comment)

      actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()

      data =
        File.read!("test/fixtures/mastodon-announce.json")
        |> Jason.decode!()
        |> Map.put("object", comment_url)

      Mock
      |> expect(:call, fn
        %{method: :get, url: actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: actor_data}}
      end)

      {:ok, _, %Comment{actor: %Actor{url: actor_url}, url: comment_url_2}} =
        Transmogrifier.handle_incoming(data)

      assert actor_url == actor.url

      assert comment_url == comment_url_2
    end
  end

  describe "handle incoming update activities" do
    test "it works for incoming update activities on actors" do
      use_cassette "activity_pub/update_actor_activity" do
        data = File.read!("test/fixtures/mastodon-post-activity.json") |> Jason.decode!()

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

        {:ok, %Activity{data: _data, local: false}, _} =
          Transmogrifier.handle_incoming(update_data)

        {:ok, %Actor{} = actor} = Actors.get_actor_by_url(update_data["actor"])
        assert actor.name == "nextsoft"

        assert actor.summary == "<p>Some bio</p>"
      end
    end

    test "it works for incoming update activities on events" do
      use_cassette "activity_pub/event_update_activities" do
        data = File.read!("test/fixtures/mobilizon-post-activity.json") |> Jason.decode!()

        {:ok, %Activity{data: data, local: false}, %Event{id: event_id}} =
          Transmogrifier.handle_incoming(data)

        assert_enqueued(
          worker: Mobilizon.Service.Workers.BuildSearch,
          args: %{event_id: event_id, op: :insert_search_event}
        )

        assert %{success: 1, failure: 0} == Oban.drain_queue(queue: :search)

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

        {:ok, %Activity{data: data, local: false}, _} =
          Transmogrifier.handle_incoming(update_data)

        %Event{} = event = Events.get_event_by_url(data["object"]["id"])

        assert_enqueued(
          worker: Mobilizon.Service.Workers.BuildSearch,
          args: %{event_id: event_id, op: :update_search_event}
        )

        assert %{success: 1, failure: 0} == Oban.drain_queue(queue: :search)

        assert event.title == "My updated event"

        assert event.description == data["object"]["content"]
      end
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

      :error = Transmogrifier.handle_incoming(data)

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
      deleted_actor_url = "https://framapiaf.org/users/admin"

      data =
        File.read!("test/fixtures/mastodon-delete-user.json")
        |> Jason.decode!()
        |> Map.put("actor", url)

      deleted_actor_data =
        File.read!("test/fixtures/mastodon-actor.json")
        |> Jason.decode!()
        |> Map.put("id", deleted_actor_url)

      Mock
      |> expect(:call, fn
        %{url: ^deleted_actor_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: deleted_actor_data}}
      end)

      assert capture_log(fn ->
               assert :error == Transmogrifier.handle_incoming(data)
             end) =~ "Object origin check failed"

      assert Actors.get_actor_by_url(url)
    end
  end

  describe "handle tombstones" do
    setup :verify_on_exit!

    # This is a hack to handle fetching tombstones
    test "works for incoming tombstone creations" do
      %Comment{url: comment_url} = comment = insert(:comment, local: false)
      tombstone = build(:tombstone, uri: comment_url)
      data = Convertible.model_to_as(tombstone)

      activity = %{
        "type" => "Create",
        "to" => data["to"],
        "cc" => data["cc"],
        "actor" => data["actor"],
        "attributedTo" => data["attributedTo"],
        "object" => data
      }

      {:ok, _activity, %Comment{url: comment_url}} = Transmogrifier.handle_incoming(activity)
      assert comment_url == comment.url
      assert %Comment{} = comment = Discussions.get_comment_from_url(comment_url)
      assert %Tombstone{} = Tombstone.find_tombstone(comment_url)
      refute is_nil(comment.deleted_at)
    end
  end

  #     test "it works for incoming blocks" do
  #       user = insert(:user)

  #       data =
  #         File.read!("test/fixtures/mastodon-block-activity.json")
  #         |> Jason.decode!()
  #         |> Map.put("object", user.ap_id)

  #       {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(data)

  #       assert data["type"] == "Block"
  #       assert data["object"] == user.ap_id
  #       assert data["actor"] == "http://mastodon.example.org/users/admin"

  #       blocker = User.get_by_ap_id(data["actor"])

  #       assert User.blocks?(blocker, user)
  #     end

  #     test "incoming blocks successfully tear down any follow relationship" do
  #       blocker = insert(:user)
  #       blocked = insert(:user)

  #       data =
  #         File.read!("test/fixtures/mastodon-block-activity.json")
  #         |> Jason.decode!()
  #         |> Map.put("object", blocked.ap_id)
  #         |> Map.put("actor", blocker.ap_id)

  #       {:ok, blocker} = User.follow(blocker, blocked)
  #       {:ok, blocked} = User.follow(blocked, blocker)

  #       assert User.following?(blocker, blocked)
  #       assert User.following?(blocked, blocker)

  #       {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(data)

  #       assert data["type"] == "Block"
  #       assert data["object"] == blocked.ap_id
  #       assert data["actor"] == blocker.ap_id

  #       blocker = User.get_by_ap_id(data["actor"])
  #       blocked = User.get_by_ap_id(data["object"])

  #       assert User.blocks?(blocker, blocked)

  #       refute User.following?(blocker, blocked)
  #       refute User.following?(blocked, blocker)
  #     end

  #     test "it works for incoming unblocks with an existing block" do
  #       user = insert(:user)

  #       block_data =
  #         File.read!("test/fixtures/mastodon-block-activity.json")
  #         |> Jason.decode!()
  #         |> Map.put("object", user.ap_id)

  #       {:ok, %Activity{data: _, local: false}} = Transmogrifier.handle_incoming(block_data)

  #       data =
  #         File.read!("test/fixtures/mastodon-unblock-activity.json")
  #         |> Jason.decode!()
  #         |> Map.put("object", block_data)

  #       {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(data)
  #       assert data["type"] == "Undo"
  #       assert data["object"]["type"] == "Block"
  #       assert data["object"]["object"] == user.ap_id
  #       assert data["actor"] == "http://mastodon.example.org/users/admin"

  #       blocker = User.get_by_ap_id(data["actor"])

  #       refute User.blocks?(blocker, user)
  #     end

  describe "handle incoming flag activities" do
    test "it accepts Flag activities" do
      %Actor{url: reporter_url} = Relay.get_actor()
      %Actor{url: reported_url} = reported = insert(:actor)

      %Comment{url: comment_url} = _comment = insert(:comment, actor: reported)

      message = %{
        "@context" => "https://www.w3.org/ns/activitystreams",
        "to" => [],
        "cc" => [reported_url],
        "object" => [reported_url, comment_url],
        "type" => "Flag",
        "content" => "blocked AND reported!!!",
        "actor" => reporter_url
      }

      assert {:ok, activity, _} = Transmogrifier.handle_incoming(message)

      assert activity.data["object"] == [reported_url, comment_url]
      assert activity.data["content"] == "blocked AND reported!!!"
      assert activity.data["actor"] == reporter_url
      assert activity.data["cc"] == []
    end
  end

  describe "prepare outgoing" do
    test "it turns mentions into tags" do
      actor = insert(:actor)
      other_actor = insert(:actor)

      {:ok, activity, _} =
        API.Comments.create_comment(%{
          actor_id: actor.id,
          text: "hey, @#{other_actor.preferred_username}, how are ya? #2hu"
        })

      {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)
      object = modified["object"]

      expected_mention = %{
        "href" => other_actor.url,
        "name" => "@#{other_actor.preferred_username}",
        "type" => "Mention"
      }

      expected_tag = %{
        "href" => Endpoint.url() <> "/tags/2hu",
        "type" => "Hashtag",
        "name" => "#2hu"
      }

      assert Enum.member?(object["tag"], expected_tag)
      assert Enum.member?(object["tag"], expected_mention)
    end

    test "it adds the json-ld context and the discussion property" do
      actor = insert(:actor)

      {:ok, activity, _} = API.Comments.create_comment(%{actor_id: actor.id, text: "hey"})

      {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)

      assert modified["@context"] == Utils.make_json_ld_header()["@context"]
    end

    test "it sets the 'attributedTo' property to the actor of the object if it doesn't have one" do
      actor = insert(:actor)

      {:ok, activity, _} = API.Comments.create_comment(%{actor_id: actor.id, text: "hey"})

      {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)

      assert modified["object"]["actor"] == modified["object"]["attributedTo"]
    end

    test "it strips internal hashtag data" do
      actor = insert(:actor)

      {:ok, activity, _} = API.Comments.create_comment(%{actor_id: actor.id, text: "#2hu"})

      expected_tag = %{
        "href" => Endpoint.url() <> "/tags/2hu",
        "type" => "Hashtag",
        "name" => "#2hu"
      }

      {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)

      assert modified["object"]["tag"] == [expected_tag]
    end

    test "it strips internal fields" do
      actor = insert(:actor)

      {:ok, activity, _} = API.Comments.create_comment(%{actor_id: actor.id, text: "#2hu"})

      {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)

      # TODO : When and if custom emoji are implemented, this should be 2
      assert length(modified["object"]["tag"]) == 1

      assert is_nil(modified["object"]["emoji"])
      assert is_nil(modified["object"]["likes"])
      assert is_nil(modified["object"]["like_count"])
      assert is_nil(modified["object"]["announcements"])
      assert is_nil(modified["object"]["announcement_count"])
      assert is_nil(modified["object"]["context_id"])
    end
  end

  describe "actor origin check" do
    test "it rejects objects with a bogus origin" do
      data =
        File.read!("test/fixtures/https__info.pleroma.site_activity.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{method: :get, url: "https://info.pleroma.site/activity.json"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}
      end)

      {:error, _} = ActivityPub.fetch_object_from_url("https://info.pleroma.site/activity.json")
    end

    test "it rejects activities which reference objects with bogus origins" do
      data =
        File.read!("test/fixtures/https__info.pleroma.site_activity.json")
        |> Jason.decode!()

      Mock
      |> expect(:call, fn
        %{method: :get, url: "https://info.pleroma.site/activity.json"}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}
      end)

      data = %{
        "@context" => "https://www.w3.org/ns/activitystreams",
        "id" => "https://framapiaf.org/users/admin/activities/1234",
        "actor" => "https://framapiaf.org/users/admin",
        "to" => ["https://www.w3.org/ns/activitystreams#Public"],
        "object" => "https://info.pleroma.site/activity.json",
        "type" => "Announce"
      }

      :error = Transmogrifier.handle_incoming(data)
    end
  end
end
