defmodule Eventos.Service.Activitypub.ActivitypubTest do

  use Eventos.DataCase

  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Accounts.Account
  alias Eventos.Service.ActivityPub
  alias Eventos.Activity

  describe "fetching account from it's url" do
    test "returns an account" do
      assert {:ok, %Account{username: "tcit@framapiaf.org"} = account} = ActivityPub.make_account_from_nickname("tcit@framapiaf.org")
    end
  end

  describe "create activities" do
    test "removes doubled 'to' recipients" do
      account = insert(:account)

      {:ok, activity} =
        ActivityPub.create(%{
          to: ["user1", "user1", "user2"],
          actor: account,
          context: "",
          object: %{}
        })

      assert activity.data["to"] == ["user1", "user2"]
      assert activity.actor == account.url
      assert activity.recipients == ["user1", "user2"]
    end
  end

  describe "fetching an object" do
    test "it fetches an object" do
      {:ok, object} =
        ActivityPub.fetch_event_from_url("https://social.tcit.fr/@tcit/99908779444618462")

      {:ok, object_again} =
        ActivityPub.fetch_event_from_url("https://social.tcit.fr/@tcit/99908779444618462")

      assert object == object_again
    end
  end

  describe "deletion" do
    test "it creates a delete activity and deletes the original event" do
      event = insert(:event)
      event = Events.get_event_full_by_url!(event.url)
      {:ok, delete} = ActivityPub.delete(event)

      assert delete.data["type"] == "Delete"
      assert delete.data["actor"] == event.organizer_account.url
      assert delete.data["object"] == event.url

      assert Events.get_event_by_url!(event.url) == nil
    end
  end

  describe "update" do
    test "it creates an update activity with the new user data" do
      account = insert(:account)
      account_data = EventosWeb.ActivityPub.UserView.render("account.json", %{account: account})

      {:ok, update} =
        ActivityPub.update(%{
          actor: account_data["url"],
          to: [account.url <> "/followers"],
          cc: [],
          object: account_data
        })

      assert update.data["actor"] == account.url
      assert update.data["to"] == [account.url <> "/followers"]
      assert update.data["object"]["id"] == account_data["id"]
      assert update.data["object"]["type"] == account_data["type"]
    end
  end
end
