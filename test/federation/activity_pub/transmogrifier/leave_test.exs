defmodule Mobilizon.Federation.ActivityPub.Transmogrifier.LeaveTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Transmogrifier

  describe "handle incoming leave activities on events" do
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
             |> Map.get(:elements)
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
end
