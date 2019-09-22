# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/activity_pub/activity_pub_test.exs

defmodule Mobilizon.Service.ActivityPub.ActivityPubTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.HTTPSignatures.Signature
  alias Mobilizon.Service.ActivityPub
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Mock

  setup_all do
    HTTPoison.start()
  end

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

  describe "fetching actor from it's url" do
    test "returns an actor from nickname" do
      use_cassette "activity_pub/fetch_tcit@framapiaf.org" do
        assert {:ok, %Actor{preferred_username: "tcit", domain: "framapiaf.org"} = actor} =
                 ActivityPub.make_actor_from_nickname("tcit@framapiaf.org")
      end
    end

    test "returns an actor from url" do
      use_cassette "activity_pub/fetch_framapiaf.org_users_tcit" do
        assert {:ok, %Actor{preferred_username: "tcit", domain: "framapiaf.org"}} =
                 ActivityPub.get_or_fetch_by_url("https://framapiaf.org/users/tcit")
      end
    end
  end

  describe "create activities" do
    #    test "removes doubled 'to' recipients" do
    #      actor = insert(:actor)
    #
    #      {:ok, activity, _} =
    #        ActivityPub.create(%{
    #          to: ["user1", "user1", "user2"],
    #          actor: actor,
    #          context: "",
    #          object: %{}
    #        })
    #
    #      assert activity.data["to"] == ["user1", "user2"]
    #      assert activity.actor == actor.url
    #      assert activity.recipients == ["user1", "user2"]
    #    end
  end

  describe "fetching an" do
    test "object by url" do
      use_cassette "activity_pub/fetch_framapiaf_framasoft_status" do
        {:ok, object} =
          ActivityPub.fetch_object_from_url(
            "https://framapiaf.org/users/Framasoft/statuses/102093631881522097"
          )

        {:ok, object_again} =
          ActivityPub.fetch_object_from_url(
            "https://framapiaf.org/users/Framasoft/statuses/102093631881522097"
          )

        assert object.id == object_again.id
      end
    end

    test "object reply by url" do
      use_cassette "activity_pub/fetch_framasoft_framapiaf_reply" do
        {:ok, object} =
          ActivityPub.fetch_object_from_url("https://mamot.fr/@imacrea/102094441327423790")

        assert object.in_reply_to_comment.url ==
                 "https://framapiaf.org/users/Framasoft/statuses/102093632302210150"
      end
    end

    test "object reply to a video by url" do
      use_cassette "activity_pub/fetch_reply_to_framatube" do
        {:ok, object} =
          ActivityPub.fetch_object_from_url(
            "https://diaspodon.fr/users/dada/statuses/100820008426311925"
          )

        assert object.in_reply_to_comment == nil
      end
    end
  end

  describe "deletion" do
    test "it creates a delete activity and deletes the original event" do
      event = insert(:event)
      event = Events.get_public_event_by_url_with_preload!(event.url)
      {:ok, delete, _} = ActivityPub.delete(event)

      assert delete.data["type"] == "Delete"
      assert delete.data["actor"] == event.organizer_actor.url
      assert delete.data["object"] == event.url

      assert Events.get_event_by_url(event.url) == nil
    end

    test "it deletes the original event but only locally if needed" do
      with_mock ActivityPub.Utils,
        maybe_federate: fn _ -> :ok end,
        lazy_put_activity_defaults: fn args -> args end do
        event = insert(:event)
        event = Events.get_public_event_by_url_with_preload!(event.url)
        {:ok, delete, _} = ActivityPub.delete(event, false)

        assert delete.data["type"] == "Delete"
        assert delete.data["actor"] == event.organizer_actor.url
        assert delete.data["object"] == event.url
        assert delete.local == false

        assert Events.get_event_by_url(event.url) == nil

        assert_called(ActivityPub.Utils.maybe_federate(delete))
      end
    end

    test "it creates a delete activity and deletes the original comment" do
      comment = insert(:comment)
      comment = Events.get_comment_from_url_with_preload!(comment.url)
      {:ok, delete, _} = ActivityPub.delete(comment)

      assert delete.data["type"] == "Delete"
      assert delete.data["actor"] == comment.actor.url
      assert delete.data["object"] == comment.url

      assert Events.get_comment_from_url(comment.url) == nil
    end
  end

  describe "update" do
    @updated_actor_summary "This is an updated actor"

    test "it creates an update activity with the new actor data" do
      actor = insert(:actor)
      actor_data = MobilizonWeb.ActivityPub.ActorView.render("actor.json", %{actor: actor})
      actor_data = Map.put(actor_data, "summary", @updated_actor_summary)

      {:ok, update, updated_actor} =
        ActivityPub.update(%{
          actor: actor_data["url"],
          to: [actor.url <> "/followers"],
          cc: [],
          object: actor_data
        })

      assert update.data["actor"] == actor.url
      assert update.data["to"] == [actor.url <> "/followers"]
      assert update.data["object"]["id"] == actor_data["id"]
      assert update.data["object"]["type"] == actor_data["type"]
      assert update.data["object"]["summary"] == @updated_actor_summary

      refute updated_actor.summary == actor.summary

      {:ok, %Actor{} = database_actor} = Mobilizon.Actors.get_actor_by_url(actor.url)
      assert database_actor.summary == @updated_actor_summary
      assert database_actor.preferred_username == actor.preferred_username
    end

    @updated_start_time DateTime.utc_now() |> DateTime.truncate(:second)

    test "it creates an update activity with the new event data" do
      actor = insert(:actor)
      event = insert(:event, organizer_actor: actor)
      event_data = Mobilizon.Service.ActivityPub.Converters.Event.model_to_as(event)
      event_data = Map.put(event_data, "startTime", @updated_start_time)

      {:ok, update, updated_event} =
        ActivityPub.update(%{
          actor: actor.url,
          to: [actor.url <> "/followers"],
          cc: [],
          object: event_data
        })

      assert update.data["actor"] == actor.url
      assert update.data["to"] == [actor.url <> "/followers"]
      assert update.data["object"]["id"] == event_data["id"]
      assert update.data["object"]["type"] == event_data["type"]
      assert update.data["object"]["startTime"] == @updated_start_time

      refute updated_event.begins_on == event.begins_on

      %Event{} = database_event = Mobilizon.Events.get_event_by_url(event.url)
      assert database_event.begins_on == @updated_start_time
      assert database_event.title == event.title
    end
  end
end
