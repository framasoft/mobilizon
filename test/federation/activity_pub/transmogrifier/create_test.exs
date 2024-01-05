defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.CreateTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  import Mox
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Conversation
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.Transmogrifier
  alias Mobilizon.Service.HTTP.ActivityPub.Mock

  describe "Receive Create Notes" do
    test "it creates conversations for received comments in reply to events" do
      actor_data = File.read!("test/fixtures/mastodon-actor.json") |> Jason.decode!()

      Mock
      |> expect(:call, 2, fn
        %{method: :get, url: "https://framapiaf.org/users/admin"}, _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body:
               actor_data
               |> Map.put("id", "https://framapiaf.org/users/admin")
               |> Map.put("preferredUsername", "admin")
           }}

        %{method: :get, url: "https://framapiaf.org/users/tcit"}, _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body:
               actor_data
               |> Map.put("id", "https://framapiaf.org/users/tcit")
               |> Map.put("preferredUsername", "tcit")
           }}
      end)

      data = File.read!("test/fixtures/mastodon-post-activity-private.json") |> Jason.decode!()
      event = insert(:event)
      object = data["object"]
      object = Map.put(object, "inReplyTo", event.url)
      data = Map.put(data, "object", object)

      {:ok, _activity,
       %Conversation{
         origin_comment: %Comment{visibility: :private, id: origin_comment_id},
         last_comment: %Comment{visibility: :private, id: last_comment_id},
         participants: participants,
         event: matched_event
       }} = Transmogrifier.handle_incoming(data)

      assert origin_comment_id == last_comment_id
      assert event.id == matched_event.id
      participant_ids = participants |> Enum.map(& &1.id) |> MapSet.new()
      {:ok, tcit} = Mobilizon.Actors.get_actor_by_url("https://framapiaf.org/users/tcit")
      {:ok, admin} = Mobilizon.Actors.get_actor_by_url("https://framapiaf.org/users/admin")
      assert participant_ids == MapSet.new([event.organizer_actor_id, tcit.id, admin.id])
    end

    test "it creates conversations for received comments if we're concerned" do
      actor_data = File.read!("test/fixtures/mastodon-actor.json") |> Jason.decode!()

      Mock
      |> expect(:call, 1, fn
        %{method: :get, url: "https://framapiaf.org/users/admin"}, _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body:
               actor_data
               |> Map.put("id", "https://framapiaf.org/users/admin")
               |> Map.put("preferredUsername", "admin")
           }}
      end)

      actor = insert(:actor)
      data = File.read!("test/fixtures/mastodon-post-activity-private.json") |> Jason.decode!()
      data = Map.put(data, "to", [actor.url])

      object =
        data["object"]
        |> Map.put("to", [actor.url])
        |> Map.put("tag", [
          data["object"]["tag"]
          |> hd()
          |> Map.put("href", actor.url)
          |> Map.put("name", Actor.preferred_username_and_domain(actor))
        ])

      data = Map.put(data, "object", object)

      {:ok, _activity,
       %Conversation{
         origin_comment: %Comment{visibility: :private, id: origin_comment_id},
         last_comment: %Comment{visibility: :private, id: last_comment_id},
         participants: participants,
         event: nil
       }} = Transmogrifier.handle_incoming(data)

      assert origin_comment_id == last_comment_id
      participant_ids = participants |> Enum.map(& &1.id) |> MapSet.new()
      {:ok, admin} = Mobilizon.Actors.get_actor_by_url("https://framapiaf.org/users/admin")
      assert participant_ids == MapSet.new([actor.id, admin.id])
    end

    test "it creates conversations for received comments if we're concerned even with reply to an event" do
      actor_data = File.read!("test/fixtures/mastodon-actor.json") |> Jason.decode!()

      Mock
      |> expect(:call, 1, fn
        %{method: :get, url: "https://framapiaf.org/users/admin"}, _opts ->
          {:ok,
           %Tesla.Env{
             status: 200,
             body:
               actor_data
               |> Map.put("id", "https://framapiaf.org/users/admin")
               |> Map.put("preferredUsername", "admin")
           }}
      end)

      actor = insert(:actor)
      data = File.read!("test/fixtures/mastodon-post-activity-private.json") |> Jason.decode!()
      data = Map.put(data, "to", [actor.url])

      %Event{id: event_id, organizer_actor_id: organizer_actor_id} = event = insert(:event)

      %Comment{url: reply_to_url, id: first_reply_comment_id} =
        insert(:comment, visibility: :private, event: event)

      object =
        data["object"]
        |> Map.put("to", [actor.url])
        |> Map.put("inReplyTo", reply_to_url)
        |> Map.put("tag", [
          data["object"]["tag"]
          |> hd()
          |> Map.put("href", actor.url)
          |> Map.put("name", Actor.preferred_username_and_domain(actor))
        ])

      data = Map.put(data, "object", object)

      {:ok, _activity,
       %Conversation{
         origin_comment: %Comment{visibility: :private, id: origin_comment_id},
         last_comment: %Comment{visibility: :private, id: _last_comment_id},
         participants: participants,
         event: %Event{id: ^event_id}
       }} = Transmogrifier.handle_incoming(data)

      assert origin_comment_id == first_reply_comment_id
      participant_ids = participants |> Enum.map(& &1.id) |> MapSet.new()
      {:ok, admin} = Mobilizon.Actors.get_actor_by_url("https://framapiaf.org/users/admin")
      assert participant_ids == MapSet.new([actor.id, organizer_actor_id, admin.id])
    end
  end
end
