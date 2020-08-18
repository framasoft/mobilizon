defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.JoinTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  import ExUnit.CaptureLog
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Transmogrifier

  describe "handle incoming join activities" do
    @join_message "I want to get in!"
    test "it accepts Join activities" do
      %Actor{url: organizer_url} = organizer = insert(:actor)
      %Actor{url: participant_url} = _participant = insert(:actor)

      %Event{url: event_url} = _event = insert(:event, organizer_actor: organizer)

      join_data =
        File.read!("test/fixtures/mobilizon-join-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", participant_url)
        |> Map.put("object", event_url)
        |> Map.put("participationMessage", @join_message)

      assert {:ok, activity, %Participant{} = participant} =
               Transmogrifier.handle_incoming(join_data)

      assert participant.metadata.message == @join_message
      assert participant.role == :participant

      assert activity.data["type"] == "Accept"
      assert activity.data["object"]["object"] == event_url
      assert activity.data["object"]["id"] =~ "/join/event/"
      assert activity.data["object"]["type"] =~ "Join"
      assert activity.data["object"]["participationMessage"] == @join_message
      assert activity.data["actor"] == organizer_url
      assert activity.data["id"] =~ "/accept/join/"
    end
  end

  describe "handle incoming accept join activities" do
    test "it accepts Accept activities for Join activities" do
      %Actor{url: organizer_url} = organizer = insert(:actor)
      %Actor{} = participant_actor = insert(:actor)

      %Event{} = event = insert(:event, organizer_actor: organizer, join_options: :restricted)

      {:ok, join_activity, participation} =
        ActivityPub.join(event, participant_actor, false, %{metadata: %{role: :not_approved}})

      accept_data =
        File.read!("test/fixtures/mastodon-accept-activity.json")
        |> Jason.decode!()
        |> Map.put("actor", organizer_url)
        |> Map.put("object", participation.url)

      {:ok, accept_activity, _} = Transmogrifier.handle_incoming(accept_data)
      assert accept_activity.data["object"]["id"] == join_activity.data["id"]
      assert accept_activity.data["object"]["id"] =~ "/join/"
      assert accept_activity.data["id"] =~ "/accept/join/"

      # We don't accept already accepted Accept activities
      :error = Transmogrifier.handle_incoming(accept_data)
    end
  end

  describe "handle incoming reject join activities" do
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
      assert reject_activity.data["object"]["id"] == join_activity.data["id"]
      assert reject_activity.data["object"]["id"] =~ "/join/"
      assert reject_activity.data["id"] =~ "/reject/join/"

      # We don't accept already rejected Reject activities
      assert capture_log([level: :warn], fn ->
               assert :error == Transmogrifier.handle_incoming(reject_data)
             end) =~
               "Tried to handle an Reject activity on a Join activity with a event object but the participant is already rejected"

      # Organiser is not present since we use factories directly
      assert event.id
             |> Events.list_participants_for_event()
             |> Map.get(:elements)
             |> Enum.map(& &1.role) == [:rejected]
    end
  end
end
