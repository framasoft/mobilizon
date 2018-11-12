defmodule Mobilizon.Service.Activitypub.ActivitypubTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Events
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors
  alias Mobilizon.Service.ActivityPub

  describe "fetching actor from it's url" do
    test "returns an actor from nickname" do
      assert {:ok, %Actor{preferred_username: "tcit", domain: "framapiaf.org"} = actor} =
               ActivityPub.make_actor_from_nickname("tcit@framapiaf.org")
    end

    test "returns an actor from url" do
      assert {:ok, %Actor{preferred_username: "tcit", domain: "framapiaf.org"}} =
               Actors.get_or_fetch_by_url("https://framapiaf.org/users/tcit")
    end
  end

  describe "create activities" do
    test "removes doubled 'to' recipients" do
      actor = insert(:actor)

      {:ok, activity} =
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
      {:ok, object} =
        ActivityPub.fetch_object_from_url(
          "https://social.tcit.fr/users/tcit/statuses/99908779444618462"
        )

      {:ok, object_again} =
        ActivityPub.fetch_object_from_url(
          "https://social.tcit.fr/users/tcit/statuses/99908779444618462"
        )

      assert object == object_again
    end
  end

  describe "deletion" do
    test "it creates a delete activity and deletes the original event" do
      event = insert(:event)
      event = Events.get_event_full_by_url!(event.url)
      {:ok, delete} = ActivityPub.delete(event)

      assert delete.data["type"] == "Delete"
      assert delete.data["actor"] == event.organizer_actor.url
      assert delete.data["object"] == event.url

      assert Events.get_event_by_url(event.url) == nil
    end

    test "it creates a delete activity and deletes the original comment" do
      comment = insert(:comment)
      comment = Events.get_comment_full_from_url!(comment.url)
      {:ok, delete} = ActivityPub.delete(comment)

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

      {:ok, update} =
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
