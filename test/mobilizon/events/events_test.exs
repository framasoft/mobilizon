defmodule Mobilizon.EventsTest do
  use Mobilizon.DataCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, Participant, Session, Tag, TagRelation, Track}
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Service.Workers
  alias Mobilizon.Storage.Page

  @event_valid_attrs %{
    begins_on: "2010-04-17 14:00:00Z",
    description: "some description",
    ends_on: "2010-04-17 14:00:00Z",
    title: "some title",
    url: "some url",
    uuid: "b5126423-f1af-43e4-a923-002a03003ba4",
    category: "meeting"
  }

  describe "list_events/5" do
    setup do
      actor = insert(:actor)
      event = insert(:event, organizer_actor: actor, visibility: :public, local: true)
      Mobilizon.Config.clear_config_cache()
      {:ok, actor: actor, event: event}
    end

    test "list_events/0 returns all events", %{event: event} do
      assert event.title == hd(Events.list_events().elements).title
    end

    test "list_events/5 returns events from other instances if we follow them",
         %{event: _event} do
      events = Events.list_events().elements
      assert length(events) == 1

      %Actor{id: remote_instance_actor_id} = remote_instance_actor = insert(:instance_actor)
      %Actor{id: remote_actor_id} = insert(:actor, domain: "somedomain.tld", user: nil)
      %Event{url: remote_event_url} = insert(:event, local: false, title: "My Remote event")
      Mobilizon.Share.create(remote_event_url, remote_instance_actor_id, remote_actor_id)

      %Actor{} = own_instance_actor = Relay.get_actor()

      insert(:follower, target_actor: remote_instance_actor, actor: own_instance_actor)

      events = Events.list_events().elements
      assert length(events) == 2
      assert events |> Enum.any?(fn event -> event.title == "My Remote event" end)
    end

    test "list_events/5 doesn't return events from other instances if we don't follow them anymore",
         %{event: _event} do
      %Actor{id: remote_instance_actor_id} = insert(:instance_actor)
      %Actor{id: remote_actor_id} = insert(:actor, domain: "somedomain.tld", user: nil)
      %Event{url: remote_event_url} = insert(:event, local: false, title: "My Remote event")
      Mobilizon.Share.create(remote_event_url, remote_instance_actor_id, remote_actor_id)

      events = Events.list_events().elements
      assert length(events) == 1
      assert events |> Enum.all?(fn event -> event.title != "My Remote event" end)
    end
  end

  describe "events" do
    setup do
      actor = insert(:actor)
      event = insert(:event, organizer_actor: actor, visibility: :public, local: true)
      Workers.BuildSearch.insert_search_event(event)
      {:ok, actor: actor, event: event}
    end

    @valid_attrs %{
      begins_on: "2010-04-17 14:00:00Z",
      description: "some description",
      ends_on: "2010-04-17 14:00:00Z",
      title: "some title"
    }
    @update_attrs %{
      begins_on: "2011-05-18 15:01:01Z",
      description: "some updated description",
      ends_on: "2011-05-18 15:01:01Z",
      title: "some updated title"
    }
    @invalid_attrs %{begins_on: nil, description: nil, ends_on: nil, title: nil}

    test "get_event!/1 returns the event with given id", %{event: event} do
      assert Events.get_event!(event.id).title == event.title
      refute Ecto.assoc_loaded?(Events.get_event!(event.id).organizer_actor)
    end

    test "get_event_with_preload!/1 returns the event with given id", %{event: event} do
      assert Events.get_event_with_preload!(event.id).organizer_actor.preferred_username ==
               event.organizer_actor.preferred_username

      assert Events.get_event_with_preload!(event.id).participants == []
    end

    test "build_events_for_search/1 returns events for a given name", %{
      event: %Event{title: title} = event
    } do
      assert title == hd(Events.build_events_for_search(%{term: event.title}).elements).title

      %Event{} = event2 = insert(:event, title: "Special event")
      Workers.BuildSearch.insert_search_event(event2)

      assert event2.title ==
               Events.build_events_for_search(%{term: "Special"}).elements
               |> hd()
               |> Map.get(:title)

      assert event2.title ==
               Events.build_events_for_search(%{term: "  Spécïal  "}).elements
               |> hd()
               |> Map.get(:title)

      tag1 = insert(:tag, title: "coucou")
      tag2 = insert(:tag, title: "hola")
      %Event{} = event3 = insert(:event, title: "Nothing like it", tags: [tag1, tag2])
      Workers.BuildSearch.insert_search_event(event3)

      assert event3.title ==
               Events.build_events_for_search(%{term: "hola"}).elements |> hd() |> Map.get(:title)

      assert %Page{elements: _elements, total: 3} = Events.build_events_for_search(%{term: ""})
    end

    test "find_close_events/3 returns events in the area" do
      assert [] == Events.find_close_events(0, 0)

      geom = %Geo.Point{coordinates: {47.2330724, -1.55068}, srid: 4326}
      address = insert(:address, geom: geom)
      event = insert(:event, physical_address: address)

      assert [event.id] == Events.find_close_events(47.2330724, -1.55068) |> Enum.map(& &1.id)
    end

    test "create_event/1 with valid data creates a event" do
      actor = insert(:actor)
      address = insert(:address)

      valid_attrs =
        @event_valid_attrs
        |> Map.put(:organizer_actor, actor)
        |> Map.put(:organizer_actor_id, actor.id)
        |> Map.put(:address_id, address.id)

      {:ok, %Event{} = event} = Events.create_event(valid_attrs)
      assert event.begins_on == DateTime.from_naive!(~N[2010-04-17 14:00:00Z], "Etc/UTC")
      assert event.description == "some description"
      assert event.ends_on == DateTime.from_naive!(~N[2010-04-17 14:00:00Z], "Etc/UTC")
      assert event.title == "some title"

      assert %Participant{} =
               participant = hd(Events.list_participants_for_event(event.id).elements)

      assert participant.actor.id == actor.id
      assert participant.role == :creator
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, :insert, %Ecto.Changeset{}, _} = Events.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event", %{event: event} do
      assert {:ok, event} = Events.update_event(event, @update_attrs)
      assert %Event{} = event
      assert event.begins_on == DateTime.from_naive!(~N[2011-05-18 15:01:01Z], "Etc/UTC")
      assert event.description == "some updated description"
      assert event.ends_on == DateTime.from_naive!(~N[2011-05-18 15:01:01Z], "Etc/UTC")
      assert event.title == "some updated title"
    end

    test "update_event/2 with invalid data returns error changeset", %{event: event} do
      assert {:error, :update, %Ecto.Changeset{}, _} = Events.update_event(event, @invalid_attrs)
      assert event.title == Events.get_event!(event.id).title
    end

    test "delete_event/1 deletes the event", %{event: event} do
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "list_public_events_for_actor/1", %{actor: actor, event: event} do
      assert %Page{elements: [event_found], total: 1} = Events.list_public_events_for_actor(actor)
      assert event_found.title == event.title
    end

    test "list_public_events_for_actor/3", %{actor: actor, event: event} do
      event1 = insert(:event, organizer_actor: actor)

      case Events.list_public_events_for_actor(actor, 1, 10) do
        %Page{elements: events_found, total: 2} ->
          event_ids = MapSet.new(events_found |> Enum.map(& &1.id))
          assert event_ids == MapSet.new([event.id, event1.id])

        err ->
          flunk("Failed to get events for an actor #{inspect(err)}")
      end
    end

    test "list_public_events_for_actor/3 with limited results", %{actor: actor, event: event} do
      event1 = insert(:event, organizer_actor: actor)

      case Events.list_public_events_for_actor(actor, 1, 1) do
        %Page{elements: [%Event{id: event_found_id}], total: 2} ->
          assert event_found_id in [event.id, event1.id]

        err ->
          flunk("Failed to get limited events for an actor #{inspect(err)}")
      end
    end

    test "get_event_by_url/1 with valid url", %{event: %Event{id: event_id, url: event_url}} do
      assert event_id == Events.get_event_by_url(event_url).id
    end

    test "get_event_by_url/1 with bad url" do
      assert is_nil(Events.get_event_by_url("not valid"))
    end

    test "get_event_by_url!/1 with valid url", %{event: %Event{id: event_id, url: event_url}} do
      assert event_id == Events.get_event_by_url!(event_url).id
    end

    test "get_event_by_url!/1 with bad url" do
      assert_raise Ecto.NoResultsError, fn ->
        Events.get_event_by_url!("not valid")
      end
    end
  end

  describe "tags" do
    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    test "list_tags/0 returns all tags" do
      tag = insert(:tag)
      assert [tag.id] == Events.list_tags() |> Enum.map(& &1.id)
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = insert(:tag)
      assert Events.get_tag!(tag.id).id == tag.id
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Events.create_tag(@valid_attrs)
      assert tag.title == "some title"
      assert tag.slug == "some-title"

      assert {:ok, %Tag{} = tag2} = Events.create_tag(@valid_attrs)
      assert tag2.title == "some title"
      assert tag2.slug == "some-title-1"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = insert(:tag)
      assert {:ok, tag} = Events.update_tag(tag, @update_attrs)
      assert %Tag{} = tag
      assert tag.title == "some updated title"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = insert(:tag)
      assert {:error, %Ecto.Changeset{}} = Events.update_tag(tag, @invalid_attrs)
      assert tag.id == Events.get_tag!(tag.id).id
    end

    test "delete_tag/1 deletes the tag" do
      tag = insert(:tag)
      assert {:ok, %Tag{}} = Events.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Events.get_tag!(tag.id) end
    end
  end

  describe "tags_relations" do
    setup do
      tag1 = insert(:tag)
      tag2 = insert(:tag)
      {:ok, tag1: tag1, tag2: tag2}
    end

    test "create_tag_relation/1 with valid data creates a tag relation", %{
      tag1: %Tag{id: tag1_id} = tag1,
      tag2: %Tag{id: tag2_id} = tag2
    } do
      assert {:ok, %TagRelation{}} =
               Events.create_tag_relation(%{tag_id: tag1_id, link_id: tag2_id})

      assert Events.are_tags_linked(tag1, tag2)
      assert Events.are_tags_linked(tag2, tag1)
    end

    test "create_tag_relation/1 with invalid data returns error changeset", %{
      tag1: %Tag{} = tag1,
      tag2: %Tag{} = tag2
    } do
      assert {:error, %Ecto.Changeset{}} =
               Events.create_tag_relation(%{tag_id: nil, link_id: nil})

      refute Events.are_tags_linked(tag1, tag2)
    end

    test "delete_tag_relation/1 deletes the tag relation" do
      tag_relation = insert(:tag_relation)
      assert {:ok, %TagRelation{}} = Events.delete_tag_relation(tag_relation)
    end

    test "list_tag_neighbors/2 return the connected tags for a given tag", %{
      tag1: %Tag{} = tag1,
      tag2: %Tag{} = tag2
    } do
      tag3 = insert(:tag)
      tag4 = insert(:tag)

      assert {:ok, %TagRelation{}} =
               Events.create_tag_relation(%{tag_id: tag1.id, link_id: tag2.id})

      assert {:ok, %TagRelation{}} =
               Events.create_tag_relation(%{tag_id: tag2.id, link_id: tag1.id})

      assert {:ok, %TagRelation{}} =
               Events.create_tag_relation(%{tag_id: tag3.id, link_id: tag2.id})

      assert {:ok, %TagRelation{}} =
               Events.create_tag_relation(%{tag_id: tag4.id, link_id: tag1.id})

      assert {:ok, %TagRelation{}} =
               Events.create_tag_relation(%{tag_id: tag4.id, link_id: tag1.id})

      assert {:ok, %TagRelation{}} =
               Events.create_tag_relation(%{tag_id: tag4.id, link_id: tag1.id})

      assert {:error,
              %Ecto.Changeset{
                errors: [
                  tag_id:
                    {"Can't add a relation on self",
                     [constraint: :check, constraint_name: "no_self_loops_check"]}
                ]
              }} = Events.create_tag_relation(%{tag_id: tag1.id, link_id: tag1.id})

      # The order is preserved, since tag4 has one more relation than tag2
      assert [tag4, tag2] == Events.list_tag_neighbors(tag1)
    end
  end

  describe "participants" do
    @valid_attrs %{role: :creator}
    @update_attrs %{role: :moderator}
    @invalid_attrs %{role: :no_such_role}

    setup do
      actor = insert(:actor)

      event =
        insert(:event, organizer_actor: actor, participant_stats: %{creator: 1, participant: 1})

      participant = insert(:participant, actor: actor, event: event)
      {:ok, participant: participant, event: event, actor: actor}
    end

    test "get_participant!/1 returns the participant for a given event and given actor", %{
      event: %Event{id: event_id},
      actor: %Actor{id: actor_id}
    } do
      assert event_id == Events.get_participant!(event_id, actor_id).event_id
      assert actor_id == Events.get_participant!(event_id, actor_id).actor_id
    end

    test "create_participant/1 with valid data creates a participant" do
      actor = insert(:actor)
      event = insert(:event)
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)
      valid_attrs = Map.put(valid_attrs, :actor_id, actor.id)

      case Events.create_participant(valid_attrs) do
        {:ok, %Participant{} = participant} ->
          assert participant.event_id == event.id
          assert participant.actor_id == actor.id
          assert participant.role == :creator

        err ->
          flunk("Failed to create a participant #{inspect(err)}")
      end
    end

    test "create_participant/1 with invalid data returns error changeset" do
      assert {:error, :participant, %Ecto.Changeset{}, _} =
               Events.create_participant(@invalid_attrs)
    end

    test "update_participant/2 with valid data updates the participant", %{
      participant: participant
    } do
      case Events.update_participant(participant, @update_attrs) do
        {:ok, %Participant{} = participant} ->
          assert participant.role == :moderator

        err ->
          flunk("Failed to update a participant #{inspect(err)}")
      end
    end

    test "update_participant/2 with invalid data returns error changeset", %{
      participant: participant
    } do
      assert {:error, :participant, %Ecto.Changeset{}, %{}} =
               Events.update_participant(participant, @invalid_attrs)
    end

    test "delete_participant/1 deletes the participant", %{participant: participant} do
      assert {:ok, %Participant{}} = Events.delete_participant(participant)
    end
  end

  describe "sessions" do
    @valid_attrs %{
      audios_urls: "some audios_urls",
      language: "some language",
      long_abstract: "some long_abstract",
      short_abstract: "some short_abstract",
      slides_url: "some slides_url",
      subtitle: "some subtitle",
      title: "some title",
      videos_urls: "some videos_urls"
    }
    @update_attrs %{
      audios_urls: "some updated audios_urls",
      language: "some updated language",
      long_abstract: "some updated long_abstract",
      short_abstract: "some updated short_abstract",
      slides_url: "some updated slides_url",
      subtitle: "some updated subtitle",
      title: "some updated title",
      videos_urls: "some updated videos_urls"
    }
    @invalid_attrs %{
      audios_urls: nil,
      language: nil,
      long_abstract: nil,
      short_abstract: nil,
      slides_url: nil,
      subtitle: nil,
      title: nil,
      videos_urls: nil
    }

    test "list_sessions/0 returns all sessions" do
      session = insert(:session)
      assert [session.id] == Events.list_sessions() |> Enum.map(& &1.id)
    end

    test "list_sessions_for_event/1 returns sessions for an event" do
      event = insert(:event)
      session = insert(:session, event: event)
      assert event |> Events.list_sessions_for_event() |> Enum.map(& &1.id) == [session.id]
    end

    test "get_session!/1 returns the session with given id" do
      session = insert(:session)
      assert Events.get_session!(session.id).id == session.id
    end

    test "create_session/1 with valid data creates a session" do
      event = insert(:event)
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)
      assert {:ok, %Session{} = session} = Events.create_session(valid_attrs)
      assert session.audios_urls == "some audios_urls"
      assert session.language == "some language"
      assert session.long_abstract == "some long_abstract"
      assert session.short_abstract == "some short_abstract"
      assert session.slides_url == "some slides_url"
      assert session.subtitle == "some subtitle"
      assert session.title == "some title"
      assert session.videos_urls == "some videos_urls"
    end

    test "create_session/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_session(@invalid_attrs)
    end

    test "update_session/2 with valid data updates the session" do
      session = insert(:session)
      assert {:ok, %Session{} = session} = Events.update_session(session, @update_attrs)
      assert session.audios_urls == "some updated audios_urls"
      assert session.language == "some updated language"
      assert session.long_abstract == "some updated long_abstract"
      assert session.short_abstract == "some updated short_abstract"
      assert session.slides_url == "some updated slides_url"
      assert session.subtitle == "some updated subtitle"
      assert session.title == "some updated title"
      assert session.videos_urls == "some updated videos_urls"
    end

    test "update_session/2 with invalid data returns error changeset" do
      session = insert(:session)
      assert {:error, %Ecto.Changeset{}} = Events.update_session(session, @invalid_attrs)
      assert session.title == Events.get_session!(session.id).title
    end

    test "delete_session/1 deletes the session" do
      session = insert(:session)
      assert {:ok, %Session{}} = Events.delete_session(session)
      assert_raise Ecto.NoResultsError, fn -> Events.get_session!(session.id) end
    end
  end

  describe "tracks" do
    @valid_attrs %{color: "some color", description: "some description", name: "some name"}
    @update_attrs %{
      color: "some updated color",
      description: "some updated description",
      name: "some updated name"
    }
    @invalid_attrs %{color: nil, description: nil, name: nil}

    test "list_tracks/0 returns all tracks" do
      track = insert(:track)
      assert [track.id] == Events.list_tracks() |> Enum.map(& &1.id)
    end

    test "list_sessions_for_track/1 returns sessions for an event" do
      event = insert(:event)
      track = insert(:track, event: event)
      session = insert(:session, track: track, event: event)
      assert track |> Events.list_sessions_for_track() |> Enum.map(& &1.id) == [session.id]
    end

    test "get_track!/1 returns the track with given id" do
      track = insert(:track)
      assert Events.get_track!(track.id).id == track.id
    end

    test "create_track/1 with valid data creates a track" do
      event = insert(:event)
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)
      assert {:ok, %Track{} = track} = Events.create_track(valid_attrs)
      assert track.color == "some color"
      assert track.description == "some description"
      assert track.name == "some name"
    end

    test "create_track/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_track(@invalid_attrs)
    end

    test "update_track/2 with valid data updates the track" do
      track = insert(:track)
      {:ok, %Track{} = track} = Events.update_track(track, @update_attrs)
      assert track.color == "some updated color"
      assert track.description == "some updated description"
      assert track.name == "some updated name"
    end

    test "update_track/2 with invalid data returns error changeset" do
      track = insert(:track)
      assert {:error, %Ecto.Changeset{}} = Events.update_track(track, @invalid_attrs)
      assert track.color == Events.get_track!(track.id).color
    end

    test "delete_track/1 deletes the track" do
      track = insert(:track)
      assert {:ok, %Track{}} = Events.delete_track(track)
      assert_raise Ecto.NoResultsError, fn -> Events.get_track!(track.id) end
    end
  end
end
