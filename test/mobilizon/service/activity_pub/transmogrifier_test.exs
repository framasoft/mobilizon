# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/activity_pub/transmogrifier_test.exs

defmodule Mobilizon.Service.ActivityPub.TransmogrifierTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Comment, Event, Participant}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.{Utils, Activity}
  alias Mobilizon.Service.ActivityPub.Transmogrifier
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

  describe "handle incoming events" do
    test "it works for incoming events" do
      data = File.read!("test/fixtures/mobilizon-post-activity.json") |> Jason.decode!()

      {:ok, %Activity{data: data, local: false}, %Event{} = event} =
        Transmogrifier.handle_incoming(data)

      assert data["id"] ==
               "https://event1.tcit.fr/@tcit/events/109ccdfd-ee3e-46e1-a877-6c228763df0c/activity"

      assert data["to"] == ["https://www.w3.org/ns/activitystreams#Public"]
      #
      #      assert data["cc"] == [
      #               "https://framapiaf.org/users/admin/followers",
      #               "http://localtesting.pleroma.lol/users/lain"
      #             ]

      assert data["actor"] == "https://event1.tcit.fr/@tcit"

      object = data["object"]

      assert object["id"] ==
               "https://event1.tcit.fr/@tcit/events/109ccdfd-ee3e-46e1-a877-6c228763df0c"

      assert object["to"] == ["https://www.w3.org/ns/activitystreams#Public"]

      #      assert object["cc"] == [
      #               "https://framapiaf.org/users/admin/followers",
      #               "http://localtesting.pleroma.lol/users/lain"
      #             ]

      assert object["actor"] == "https://event1.tcit.fr/@tcit"
      assert object["location"]["name"] == "Locaux de Framasoft"
      assert object["attributedTo"] == "https://event1.tcit.fr/@tcit"

      assert event.physical_address.street == "10 Rue Jangot"

      assert event.physical_address.url ==
               "https://event1.tcit.fr/address/eeecc11d-0030-43e8-a897-6422876372jd"

      {:ok, %Actor{}} = Actors.get_actor_by_url(object["actor"])
    end
  end

  describe "handle incoming notices" do
    # test "it ignores an incoming comment if we already have it" do
    #   comment = insert(:comment)

    #   activity = %{
    #     "type" => "Create",
    #     "to" => ["https://www.w3.org/ns/activitystreams#Public"],
    #     "actor" => comment.actor.url,
    #     "object" => Utils.make_comment_data(comment)
    #   }

    #   data =
    #     File.read!("test/fixtures/mastodon-post-activity.json")
    #     |> Jason.decode!()
    #     |> Map.put("object", activity["object"])

    #   {:ok, returned_activity, _} = Transmogrifier.handle_incoming(data)

    #   assert activity == returned_activity.data
    # end

    # test "it fetches replied-to activities if we don't have them" do
    #   data =
    #     File.read!("test/fixtures/mastodon-post-activity.json")
    #     |> Jason.decode!()

    #   object =
    #     data["object"]
    #     |> Map.put("inReplyTo", "https://shitposter.club/notice/2827873")

    #   data =
    #     data
    #     |> Map.put("object", object)

    #   {:ok, returned_activity, _} = Transmogrifier.handle_incoming(data)

    #   assert activity =
    #            Activity.get_create_activity_by_object_ap_id(
    #              "tag:shitposter.club,2017-05-05:noticeId=2827873:objectType=comment"
    #            )

    #   assert returned_activity.data["object"]["inReplyToAtomUri"] ==
    #            "https://shitposter.club/notice/2827873"

    #   assert returned_activity.data["object"]["inReplyToStatusId"] == activity.id
    # end

    test "it works for incoming notices" do
      data = File.read!("test/fixtures/mastodon-post-activity.json") |> Jason.decode!()

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

      assert data["id"] == "https://framapiaf.org/users/admin/statuses/99512778738411822/activity"

      assert data["to"] == ["https://www.w3.org/ns/activitystreams#Public"]

      assert data["cc"] == [
               "https://framapiaf.org/users/admin/followers",
               "http://mobilizon.com/@tcit"
             ]

      assert data["actor"] == "https://framapiaf.org/users/admin"

      object = data["object"]
      assert object["id"] == "https://framapiaf.org/users/admin/statuses/99512778738411822"

      assert object["to"] == ["https://www.w3.org/ns/activitystreams#Public"]

      assert object["cc"] == [
               "https://framapiaf.org/users/admin/followers",
               "http://localtesting.pleroma.lol/users/lain"
             ]

      assert object["actor"] == "https://framapiaf.org/users/admin"
      assert object["attributedTo"] == "https://framapiaf.org/users/admin"

      assert object["sensitive"] == true

      {:ok, %Actor{}} = Actors.get_actor_by_url(object["actor"])
    end

    test "it works for incoming notices with hashtags" do
      data = File.read!("test/fixtures/mastodon-post-activity-hashtag.json") |> Jason.decode!()

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)
      assert Enum.at(data["object"]["tag"], 1)["name"] == "#moo"
    end

    #     test "it works for incoming notices with contentMap" do
    #       data =
    #         File.read!("test/fixtures/mastodon-post-activity-contentmap.json") |> Jason.decode!()

    #       {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

    #       assert data["object"]["content"] ==
    #                "<p><span class=\"h-card\"><a href=\"http://localtesting.pleroma.lol/users/lain\" class=\"u-url mention\">@<span>lain</span></a></span></p>"
    #     end

    #     test "it works for incoming notices with to/cc not being an array (kroeg)" do
    #       data = File.read!("test/fixtures/kroeg-post-activity.json") |> Jason.decode!()

    #       {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

    #       assert data["object"]["content"] ==
    #                "<p>henlo from my Psion netBook</p><p>message sent from my Psion netBook</p>"
    #     end

    #     test "it works for incoming announces with actor being inlined (kroeg)" do
    #       data = File.read!("test/fixtures/kroeg-announce-with-inline-actor.json") |> Jason.decode!()

    #       {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

    #       assert data["actor"] == "https://puckipedia.com/"
    #     end

    #     test "it works for incoming notices with tag not being an array (kroeg)" do
    #       data = File.read!("test/fixtures/kroeg-array-less-emoji.json") |> Jason.decode!()

    #       {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

    #       assert data["object"]["emoji"] == %{
    #                "icon_e_smile" => "https://puckipedia.com/forum/images/smilies/icon_e_smile.png"
    #              }

    #       data = File.read!("test/fixtures/kroeg-array-less-hashtag.json") |> Jason.decode!()

    #       {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

    #       assert "test" in data["object"]["tag"]
    #     end

    test "it works for incoming notices with url not being a string (prismo)" do
      data = File.read!("test/fixtures/prismo-url-map.json") |> Jason.decode!()

      assert {:error, :not_supported} == Transmogrifier.handle_incoming(data)
      # Pages are not supported
      # {:ok, %Activity{data: data, local: false}} = Transmogrifier.handle_incoming(data)

      # assert data["object"]["url"] == "https://prismo.news/posts/83"
    end

    test "it works for incoming follow requests" do
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

    test "it works for incoming announces" do
      data = File.read!("test/fixtures/mastodon-announce.json") |> Jason.decode!()

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

      assert data["actor"] == "https://framapiaf.org/users/Framasoft"
      assert data["type"] == "Announce"

      assert data["id"] ==
               "https://framapiaf.org/users/Framasoft/statuses/102501959686438400/activity"

      assert data["object"] ==
               "https://framapiaf.org/users/Framasoft/statuses/102501959686438400"

      assert %Comment{} = Events.get_comment_from_url(data["object"])
    end

    test "it works for incoming announces with an existing activity" do
      comment = insert(:comment)

      data =
        File.read!("test/fixtures/mastodon-announce.json")
        |> Jason.decode!()
        |> Map.put("object", comment.url)

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

      assert data["actor"] == "https://framapiaf.org/users/Framasoft"
      assert data["type"] == "Announce"

      assert data["id"] ==
               "https://framapiaf.org/users/Framasoft/statuses/102501959686438400/activity"

      assert data["object"] == comment.url
    end

    test "it works for incoming update activities on actors" do
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

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(update_data)

      {:ok, %Actor{} = actor} = Actors.get_actor_by_url(data["actor"])
      assert actor.name == "nextsoft"

      assert actor.summary == "<p>Some bio</p>"
    end

    test "it works for incoming update activities on events" do
      data = File.read!("test/fixtures/mobilizon-post-activity.json") |> Jason.decode!()

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)
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

    test "it works for incoming deletes" do
      %Actor{url: actor_url} = actor = insert(:actor)
      %Comment{url: comment_url} = insert(:comment, actor: actor)

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

      assert Events.get_comment_from_url(comment_url)

      {:ok, %Activity{local: false}, _} = Transmogrifier.handle_incoming(data)

      refute Events.get_comment_from_url(comment_url)
    end

    #     TODO : make me ASAP
    #     test "it fails for incoming deletes with spoofed origin" do
    #       activity = insert(:note_activity)

    #       data =
    #         File.read!("test/fixtures/mastodon-delete.json")
    #         |> Jason.decode!()

    #       object =
    #         data["object"]
    #         |> Map.put("id", activity.data["object"]["id"])

    #       data =
    #         data
    #         |> Map.put("object", object)

    #       :error = Transmogrifier.handle_incoming(data)

    #       assert Repo.get(Activity, activity.id)
    #     end

    test "it works for incoming unannounces with an existing notice" do
      comment = insert(:comment)

      announce_data =
        File.read!("test/fixtures/mastodon-announce.json")
        |> Jason.decode!()
        |> Map.put("object", comment.url)

      {:ok, %Activity{data: announce_data, local: false}, _} =
        Transmogrifier.handle_incoming(announce_data)

      data =
        File.read!("test/fixtures/mastodon-undo-announce.json")
        |> Jason.decode!()
        |> Map.put("object", announce_data)
        |> Map.put("actor", announce_data["actor"])

      {:ok, %Activity{data: data, local: false}, _} = Transmogrifier.handle_incoming(data)

      assert data["type"] == "Undo"
      assert data["object"]["type"] == "Announce"
      assert data["object"]["object"] == comment.url

      assert data["object"]["id"] ==
               "https://framapiaf.org/users/Framasoft/statuses/102501959686438400/activity"
    end

    test "it works for incomming unfollows with an existing follow" do
      actor = insert(:actor)

      follow_data =
        File.read!("test/fixtures/mastodon-follow-activity.json")
        |> Jason.decode!()
        |> Map.put("object", actor.url)

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
      assert activity.data["object"] == follow_activity.data["id"]
      assert activity.data["object"] =~ "/follow/"
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

    test "it rejects activities without a valid ID" do
      actor = insert(:actor)

      data =
        File.read!("test/fixtures/mastodon-follow-activity.json")
        |> Jason.decode!()
        |> Map.put("object", actor.url)
        |> Map.put("id", "")

      :error = Transmogrifier.handle_incoming(data)
    end

    test "it accepts Flag activities" do
      %Actor{url: reporter_url} = _reporter = insert(:actor)
      %Actor{url: reported_url} = reported = insert(:actor)

      %Comment{url: comment_url} = _comment = insert(:comment, actor: reported)

      message = %{
        "@context" => "https://www.w3.org/ns/activitystreams",
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
      assert activity.data["cc"] == [reported_url]
    end

    test "it accepts Join activities" do
      %Actor{url: _organizer_url} = organizer = insert(:actor)
      %Actor{url: participant_url} = _participant = insert(:actor)

      %Event{url: event_url} = _event = insert(:event, organizer_actor: organizer)

      join_data =
        File.read!("test/fixtures/mobilizon-join-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", participant_url)
        |> Map.put("object", event_url)

      assert {:ok, activity, _} = Transmogrifier.handle_incoming(join_data)

      assert activity.data["object"] == event_url
      assert activity.data["actor"] == participant_url
    end

    test "it accepts Accept activities for Join activities" do
      %Actor{url: organizer_url} = organizer = insert(:actor)
      %Actor{} = participant_actor = insert(:actor)

      %Event{} = event = insert(:event, organizer_actor: organizer, join_options: :restricted)

      {:ok, join_activity, participation} = ActivityPub.join(event, participant_actor)

      accept_data =
        File.read!("test/fixtures/mastodon-accept-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", organizer_url)
        |> Map.put("object", participation.url)

      {:ok, accept_activity, _} = Transmogrifier.handle_incoming(accept_data)
      assert accept_activity.data["object"] == join_activity.data["id"]
      assert accept_activity.data["object"] =~ "/join/"
      assert accept_activity.data["id"] =~ "/accept/join/"

      # We don't accept already accepted Accept activities
      :error = Transmogrifier.handle_incoming(accept_data)
    end

    test "it accepts Reject activities for Join activities" do
      %Actor{url: organizer_url} = organizer = insert(:actor)
      %Actor{} = participant_actor = insert(:actor)

      %Event{} = event = insert(:event, organizer_actor: organizer, join_options: :restricted)

      {:ok, join_activity, participation} = ActivityPub.join(event, participant_actor)

      reject_data =
        File.read!("test/fixtures/mastodon-reject-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", organizer_url)
        |> Map.put("object", participation.url)

      {:ok, reject_activity, _} = Transmogrifier.handle_incoming(reject_data)
      assert reject_activity.data["object"] == join_activity.data["id"]
      assert reject_activity.data["object"] =~ "/join/"
      assert reject_activity.data["id"] =~ "/reject/join/"

      # We don't accept already rejected Reject activities
      assert :error == Transmogrifier.handle_incoming(reject_data)

      # Organiser is not present since we use factories directly
      assert event.id
             |> Events.list_participants_for_event()
             |> Enum.map(& &1.id) ==
               []
    end

    test "it accepts Leave activities" do
      %Actor{url: _organizer_url} = organizer = insert(:actor)
      %Actor{url: participant_url} = participant_actor = insert(:actor)

      %Event{url: event_url} =
        event = insert(:event, organizer_actor: organizer, join_options: :restricted)

      organizer_participation =
        %Participant{} = insert(:participant, event: event, actor: organizer, role: :creator)

      {:ok, _join_activity, _participation} = ActivityPub.join(event, participant_actor)

      join_data =
        File.read!("test/fixtures/mobilizon-leave-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", participant_url)
        |> Map.put("object", event_url)

      assert {:ok, activity, _} = Transmogrifier.handle_incoming(join_data)

      assert activity.data["object"] == event_url
      assert activity.data["actor"] == participant_url

      # The only participant left is the organizer
      assert event.id
             |> Events.list_participants_for_event()
             |> Enum.map(& &1.id) ==
               [organizer_participation.id]
    end

    test "it refuses Leave activities when actor is the only organizer" do
      %Actor{url: organizer_url} = organizer = insert(:actor)

      %Event{url: event_url} =
        event = insert(:event, organizer_actor: organizer, join_options: :restricted)

      %Participant{} = insert(:participant, event: event, actor: organizer, role: :creator)

      join_data =
        File.read!("test/fixtures/mobilizon-leave-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", organizer_url)
        |> Map.put("object", event_url)

      assert :error = Transmogrifier.handle_incoming(join_data)
    end
  end

  describe "prepare outgoing" do
    test "it turns mentions into tags" do
      actor = insert(:actor)
      other_actor = insert(:actor)

      {:ok, activity, _} =
        MobilizonWeb.API.Comments.create_comment(
          actor.preferred_username,
          "hey, @#{other_actor.preferred_username}, how are ya? #2hu"
        )

      {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)
      object = modified["object"]

      expected_mention = %{
        "href" => other_actor.url,
        "name" => "@#{other_actor.preferred_username}",
        "type" => "Mention"
      }

      expected_tag = %{
        "href" => MobilizonWeb.Endpoint.url() <> "/tags/2hu",
        "type" => "Hashtag",
        "name" => "#2hu"
      }

      assert Enum.member?(object["tag"], expected_tag)
      assert Enum.member?(object["tag"], expected_mention)
    end

    #     test "it adds the sensitive property" do
    #       user = insert(:user)

    #       {:ok, activity} = CommonAPI.post(user, %{"status" => "#nsfw hey"})
    #       {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)

    #       assert modified["object"]["sensitive"]
    #     end

    test "it adds the json-ld context and the conversation property" do
      actor = insert(:actor)

      {:ok, activity, _} =
        MobilizonWeb.API.Comments.create_comment(actor.preferred_username, "hey")

      {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)

      assert modified["@context"] == Utils.make_json_ld_header()["@context"]
    end

    test "it sets the 'attributedTo' property to the actor of the object if it doesn't have one" do
      actor = insert(:actor)

      {:ok, activity, _} =
        MobilizonWeb.API.Comments.create_comment(actor.preferred_username, "hey")

      {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)

      assert modified["object"]["actor"] == modified["object"]["attributedTo"]
    end

    test "it strips internal hashtag data" do
      actor = insert(:actor)

      {:ok, activity, _} =
        MobilizonWeb.API.Comments.create_comment(actor.preferred_username, "#2hu")

      expected_tag = %{
        "href" => MobilizonWeb.Endpoint.url() <> "/tags/2hu",
        "type" => "Hashtag",
        "name" => "#2hu"
      }

      {:ok, modified} = Transmogrifier.prepare_outgoing(activity.data)

      assert modified["object"]["tag"] == [expected_tag]
    end

    test "it strips internal fields" do
      actor = insert(:actor)

      {:ok, activity, _} =
        MobilizonWeb.API.Comments.create_comment(actor.preferred_username, "#2hu")

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

    #   describe "actor rewriting" do
    #     test "it fixes the actor URL property to be a proper URI" do
    #       data = %{
    #         "url" => %{"href" => "http://example.com"}
    #       }

    #       rewritten = Transmogrifier.maybe_fix_user_object(data)
    #       assert rewritten["url"] == "http://example.com"
    #     end
    #   end

    #   describe "actor origin containment" do
    #     test "it rejects objects with a bogus origin" do
    #       {:error, _} = ActivityPub.fetch_object_from_id("https://info.pleroma.site/activity.json")
    #     end

    #     test "it rejects activities which reference objects with bogus origins" do
    #       data = %{
    #         "@context" => "https://www.w3.org/ns/activitystreams",
    #         "id" => "http://mastodon.example.org/users/admin/activities/1234",
    #         "actor" => "http://mastodon.example.org/users/admin",
    #         "to" => ["https://www.w3.org/ns/activitystreams#Public"],
    #         "object" => "https://info.pleroma.site/activity.json",
    #         "type" => "Announce"
    #       }

    #       :error = Transmogrifier.handle_incoming(data)
    #     end

    #     test "it rejects objects when attributedTo is wrong (variant 1)" do
    #       {:error, _} = ActivityPub.fetch_object_from_id("https://info.pleroma.site/activity2.json")
    #     end

    #     test "it rejects activities which reference objects that have an incorrect attribution (variant 1)" do
    #       data = %{
    #         "@context" => "https://www.w3.org/ns/activitystreams",
    #         "id" => "http://mastodon.example.org/users/admin/activities/1234",
    #         "actor" => "http://mastodon.example.org/users/admin",
    #         "to" => ["https://www.w3.org/ns/activitystreams#Public"],
    #         "object" => "https://info.pleroma.site/activity2.json",
    #         "type" => "Announce"
    #       }

    #       :error = Transmogrifier.handle_incoming(data)
    #     end

    #     test "it rejects objects when attributedTo is wrong (variant 2)" do
    #       {:error, _} = ActivityPub.fetch_object_from_id("https://info.pleroma.site/activity3.json")
    #     end

    #     test "it rejects activities which reference objects that have an incorrect attribution (variant 2)" do
    #       data = %{
    #         "@context" => "https://www.w3.org/ns/activitystreams",
    #         "id" => "http://mastodon.example.org/users/admin/activities/1234",
    #         "actor" => "http://mastodon.example.org/users/admin",
    #         "to" => ["https://www.w3.org/ns/activitystreams#Public"],
    #         "object" => "https://info.pleroma.site/activity3.json",
    #         "type" => "Announce"
    #       }

    #       :error = Transmogrifier.handle_incoming(data)
    #     end
    #   end

    #   describe "general origin containment" do
    #     test "contain_origin_from_id() catches obvious spoofing attempts" do
    #       data = %{
    #         "id" => "http://example.com/~alyssa/activities/1234.json"
    #       }

    #       :error =
    #         Transmogrifier.contain_origin_from_id(
    #           "http://example.org/~alyssa/activities/1234.json",
    #           data
    #         )
    #     end

    #     test "contain_origin_from_id() allows alternate IDs within the same origin domain" do
    #       data = %{
    #         "id" => "http://example.com/~alyssa/activities/1234.json"
    #       }

    #       :ok =
    #         Transmogrifier.contain_origin_from_id(
    #           "http://example.com/~alyssa/activities/1234",
    #           data
    #         )
    #     end

    #     test "contain_origin_from_id() allows matching IDs" do
    #       data = %{
    #         "id" => "http://example.com/~alyssa/activities/1234.json"
    #       }

    #       :ok =
    #         Transmogrifier.contain_origin_from_id(
    #           "http://example.com/~alyssa/activities/1234.json",
    #           data
    #         )
    #     end

    #     test "users cannot be collided through fake direction spoofing attempts" do
    #       user =
    #         insert(:user, %{
    #           nickname: "rye@niu.moe",
    #           local: false,
    #           ap_id: "https://niu.moe/users/rye",
    #           follower_address: User.ap_followers(%User{nickname: "rye@niu.moe"})
    #         })

    #       {:error, _} = User.get_or_fetch_by_ap_id("https://n1u.moe/users/rye")
    #     end

    #     test "all objects with fake directions are rejected by the object fetcher" do
    #       {:error, _} =
    #         ActivityPub.fetch_and_contain_remote_object_from_id(
    #           "https://info.pleroma.site/activity4.json"
    #         )
    #     end
  end
end
