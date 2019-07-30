# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/test/web/activity_pub/activity_pub_test.exs

defmodule Mobilizon.Service.ActivityPub.ActivityPubTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Events
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors
  alias Mobilizon.Service.HTTPSignatures
  alias Mobilizon.Service.ActivityPub
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

  describe "setting HTTP signature" do
    test "set http signature header" do
      actor = insert(:actor)

      signature =
        HTTPSignatures.sign(actor, %{
          host: "example.com",
          "content-length": 15,
          digest: Jason.encode!(%{id: "my_id"}) |> HTTPSignatures.build_digest(),
          "(request-target)": HTTPSignatures.generate_request_target("POST", "/inbox"),
          date: HTTPSignatures.generate_date_header()
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
                 Actors.get_or_fetch_by_url("https://framapiaf.org/users/tcit")
      end
    end
  end

  describe "create activities" do
    test "removes doubled 'to' recipients" do
      actor = insert(:actor)

      {:ok, activity, _} =
        ActivityPub.create(%{
          to: ["user1", "user1", "user2"],
          actor: actor,
          context: "",
          object: %{}
        })

      assert activity.data["to"] == ["user1", "user2"]
      assert activity.actor == actor.url
      assert activity.recipients == ["user1", "user2"]
    end
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
      event = Events.get_event_full_by_url!(event.url)
      {:ok, delete, _} = ActivityPub.delete(event)

      assert delete.data["type"] == "Delete"
      assert delete.data["actor"] == event.organizer_actor.url
      assert delete.data["object"] == event.url

      assert Events.get_event_by_url(event.url) == nil
    end

    test "it creates a delete activity and deletes the original comment" do
      comment = insert(:comment)
      comment = Events.get_comment_full_from_url!(comment.url)
      {:ok, delete, _} = ActivityPub.delete(comment)

      assert delete.data["type"] == "Delete"
      assert delete.data["actor"] == comment.actor.url
      assert delete.data["object"] == comment.url

      assert Events.get_comment_from_url(comment.url) == nil
    end
  end

  describe "update" do
    test "it creates an update activity with the new actor data" do
      actor = insert(:actor)
      actor_data = MobilizonWeb.ActivityPub.ActorView.render("actor.json", %{actor: actor})

      {:ok, update, _} =
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
    end
  end
end
