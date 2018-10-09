defmodule Eventos.EventsTest do
  use Eventos.DataCase

  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Actors

  @event_valid_attrs %{
    begins_on: "2010-04-17 14:00:00.000000Z",
    description: "some description",
    ends_on: "2010-04-17 14:00:00.000000Z",
    title: "some title"
  }

  def actor_fixture do
    insert(:actor)
  end

  def address_fixture do
    insert(:address)
  end

  def event_fixture do
    insert(:event)
  end

  def category_fixture do
    insert(:category)
  end

  describe "events" do
    alias Eventos.Events.Event

    setup do
      actor = insert(:actor)
      event = insert(:event, organizer_actor: actor)
      {:ok, actor: actor, event: event}
    end

    @valid_attrs %{
      begins_on: "2010-04-17 14:00:00.000000Z",
      description: "some description",
      ends_on: "2010-04-17 14:00:00.000000Z",
      title: "some title"
    }
    @update_attrs %{
      begins_on: "2011-05-18 15:01:01.000000Z",
      description: "some updated description",
      ends_on: "2011-05-18 15:01:01.000000Z",
      title: "some updated title"
    }
    @invalid_attrs %{begins_on: nil, description: nil, ends_on: nil, title: nil}

    test "list_events/0 returns all events", %{event: event} do
      assert event.title == hd(Events.list_events()).title
    end

    test "get_event!/1 returns the event with given id", %{event: event} do
      assert Events.get_event!(event.id).title == event.title
      refute Ecto.assoc_loaded?(Events.get_event!(event.id).organizer_actor)
    end

    test "get_event_full!/1 returns the event with given id", %{event: event} do
      assert Events.get_event_full!(event.id).organizer_actor.preferred_username ==
               event.organizer_actor.preferred_username

      assert Events.get_event_full!(event.id).participants == []
    end

    test "find_events_by_name/1 returns events for a given name", %{event: event} do
      assert event.title == hd(Events.find_events_by_name(event.title)).title

      event2 = insert(:event, title: "Special event")
      assert event2.title == hd(Events.find_events_by_name("Special")).title

      event2 = insert(:event, title: "Special event")
      assert event2.title == hd(Events.find_events_by_name("  Special  ")).title

      assert [] == Events.find_events_by_name("")
    end

    test "create_event/1 with valid data creates a event" do
      actor = actor_fixture()
      category = category_fixture()
      address = address_fixture()

      valid_attrs =
        @event_valid_attrs
        |> Map.put(:organizer_actor, actor)
        |> Map.put(:organizer_actor_id, actor.id)
        |> Map.put(:category_id, category.id)
        |> Map.put(:address_id, address.id)

      assert {:ok, %Event{} = event} = Events.create_event(valid_attrs)
      assert event.begins_on == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert event.description == "some description"
      assert event.ends_on == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert event.title == "some title"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event", %{event: event} do
      assert {:ok, event} = Events.update_event(event, @update_attrs)
      assert %Event{} = event
      assert event.begins_on == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert event.description == "some updated description"
      assert event.ends_on == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert event.title == "some updated title"
    end

    test "update_event/2 with invalid data returns error changeset", %{event: event} do
      assert {:error, %Ecto.Changeset{}} = Events.update_event(event, @invalid_attrs)
      assert event.title == Events.get_event!(event.id).title
    end

    test "delete_event/1 deletes the event", %{event: event} do
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset", %{event: event} do
      assert %Ecto.Changeset{} = Events.change_event(event)
    end

    test "get_events_for_actor/1", %{actor: actor, event: event} do
      assert {:ok, [event_found], 1} = Events.get_events_for_actor(actor)
      assert event_found.title == event.title
    end

    test "get_events_for_actor/3", %{actor: actor, event: event} do
      event1 = insert(:event, organizer_actor: actor)
      assert {:ok, [event_found, event1_found], 2} = Events.get_events_for_actor(actor, 1, 10)
    end

    test "get_events_for_actor/3 with limited results", %{actor: actor, event: event} do
      event1 = insert(:event, organizer_actor: actor)
      assert {:ok, [event_found], 2} = Events.get_events_for_actor(actor, 1, 1)
    end

    test "get_event_by_url/1 with valid url", %{actor: actor, event: event} do
      assert event = Events.get_event_by_url(event.url)
    end

    test "get_event_by_url/1 with bad url", %{actor: actor, event: event} do
      refute event == Events.get_event_by_url("not valid")
    end

    test "get_event_by_url!/1 with valid url", %{actor: actor, event: event} do
      assert event = Events.get_event_by_url!(event.url)
    end

    test "get_event_by_url!/1 with bad url", %{actor: actor, event: event} do
      assert_raise Ecto.NoResultsError, fn ->
        Events.get_event_by_url!("not valid")
      end
    end
  end

  describe "categories" do
    alias Eventos.Events.Category

    setup do
      category = insert(:category)
      {:ok, category: category}
    end

    @valid_attrs %{description: "some description", picture: "some picture", title: "some title"}
    @update_attrs %{
      description: "some updated description",
      picture: "some updated picture",
      title: "some updated title"
    }
    @invalid_attrs %{description: nil, picture: nil, title: nil}

    test "list_categories/0 returns all categories", %{category: category} do
      assert Events.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id", %{category: category} do
      assert Events.get_category!(category.id) == category
    end

    test "get_category_by_title/1 return the category with given title", %{category: category} do
      assert Events.get_category_by_title(category.title) == category
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} = Events.create_category(@valid_attrs)
      assert category.description == "some description"
      assert category.picture == "some picture"
      assert category.title == "some title"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category", %{category: category} do
      assert {:ok, category} = Events.update_category(category, @update_attrs)
      assert %Category{} = category
      assert category.description == "some updated description"
      assert category.picture == "some updated picture"
      assert category.title == "some updated title"
    end

    test "update_category/2 with invalid data returns error changeset", %{category: category} do
      assert {:error, %Ecto.Changeset{}} = Events.update_category(category, @invalid_attrs)
      assert category == Events.get_category!(category.id)
    end

    test "delete_category/1 deletes the category", %{category: category} do
      assert {:ok, %Category{}} = Events.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Events.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset", %{category: category} do
      assert %Ecto.Changeset{} = Events.change_category(category)
    end
  end

  describe "tags" do
    alias Eventos.Events.Tag

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    def tag_fixture(attrs \\ %{}) do
      {:ok, tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_tag()

      tag
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Events.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Events.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Events.create_tag(@valid_attrs)
      assert tag.title == "some title"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, tag} = Events.update_tag(tag, @update_attrs)
      assert %Tag{} = tag
      assert tag.title == "some updated title"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_tag(tag, @invalid_attrs)
      assert tag == Events.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Events.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Events.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Events.change_tag(tag)
    end
  end

  describe "participants" do
    alias Eventos.Events.{Participant, Event}
    alias Eventos.Actors.Actor

    @valid_attrs %{role: 42}
    @update_attrs %{role: 43}
    @invalid_attrs %{role: nil}

    setup do
      actor = insert(:actor)
      event = insert(:event, organizer_actor: actor)
      participant = insert(:participant, actor: actor, event: event)
      {:ok, participant: participant, event: event, actor: actor}
    end

    test "list_participants/0 returns all participants", %{participant: participant} do
      assert [%Participant{} = participant] = Events.list_participants()
    end

    test "get_participant!/1 returns the participant for a given event and given actor", %{
      event: %Event{id: event_id} = _event,
      actor: %Actor{id: actor_id} = _actor
    } do
      assert %Participant{event_id: event_id, actor_id: actor_id} =
               _participant = Events.get_participant!(event_id, actor_id)
    end

    test "create_participant/1 with valid data creates a participant" do
      actor = actor_fixture()
      event = event_fixture()
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)
      valid_attrs = Map.put(valid_attrs, :actor_id, actor.id)
      assert {:ok, %Participant{} = participant} = Events.create_participant(valid_attrs)
      assert participant.role == 42
    end

    test "create_participant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_participant(@invalid_attrs)
    end

    test "update_participant/2 with valid data updates the participant", %{
      participant: participant
    } do
      assert {:ok, participant} = Events.update_participant(participant, @update_attrs)
      assert %Participant{} = participant
      assert participant.role == 43
    end

    test "update_participant/2 with invalid data returns error changeset", %{
      participant: participant
    } do
      assert {:error, %Ecto.Changeset{}} = Events.update_participant(participant, @invalid_attrs)
    end

    test "delete_participant/1 deletes the participant", %{participant: participant} do
      assert {:ok, %Participant{}} = Events.delete_participant(participant)
    end

    test "change_participant/1 returns a participant changeset", %{participant: participant} do
      assert %Ecto.Changeset{} = Events.change_participant(participant)
    end
  end

  describe "sessions" do
    alias Eventos.Events.Session

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

    def session_fixture(attrs \\ %{}) do
      event = event_fixture()
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)

      {:ok, session} =
        attrs
        |> Enum.into(valid_attrs)
        |> Events.create_session()

      session
    end

    test "list_sessions/0 returns all sessions" do
      session = session_fixture()
      assert Events.list_sessions() == [session]
    end

    test "get_session!/1 returns the session with given id" do
      session = session_fixture()
      assert Events.get_session!(session.id) == session
    end

    test "create_session/1 with valid data creates a session" do
      event = event_fixture()
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
      session = session_fixture()
      assert {:ok, session} = Events.update_session(session, @update_attrs)
      assert %Session{} = session
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
      session = session_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_session(session, @invalid_attrs)
      assert session == Events.get_session!(session.id)
    end

    test "delete_session/1 deletes the session" do
      session = session_fixture()
      assert {:ok, %Session{}} = Events.delete_session(session)
      assert_raise Ecto.NoResultsError, fn -> Events.get_session!(session.id) end
    end

    test "change_session/1 returns a session changeset" do
      session = session_fixture()
      assert %Ecto.Changeset{} = Events.change_session(session)
    end
  end

  describe "tracks" do
    alias Eventos.Events.Track

    @valid_attrs %{color: "some color", description: "some description", name: "some name"}
    @update_attrs %{
      color: "some updated color",
      description: "some updated description",
      name: "some updated name"
    }
    @invalid_attrs %{color: nil, description: nil, name: nil}

    def track_fixture(attrs \\ %{}) do
      event = event_fixture()
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)

      {:ok, track} =
        attrs
        |> Enum.into(valid_attrs)
        |> Events.create_track()

      track
    end

    test "list_tracks/0 returns all tracks" do
      track = track_fixture()
      assert Events.list_tracks() == [track]
    end

    test "get_track!/1 returns the track with given id" do
      track = track_fixture()
      assert Events.get_track!(track.id) == track
    end

    test "create_track/1 with valid data creates a track" do
      event = event_fixture()
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
      track = track_fixture()
      assert {:ok, track} = Events.update_track(track, @update_attrs)
      assert %Track{} = track
      assert track.color == "some updated color"
      assert track.description == "some updated description"
      assert track.name == "some updated name"
    end

    test "update_track/2 with invalid data returns error changeset" do
      track = track_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_track(track, @invalid_attrs)
      assert track == Events.get_track!(track.id)
    end

    test "delete_track/1 deletes the track" do
      track = track_fixture()
      assert {:ok, %Track{}} = Events.delete_track(track)
      assert_raise Ecto.NoResultsError, fn -> Events.get_track!(track.id) end
    end

    test "change_track/1 returns a track changeset" do
      track = track_fixture()
      assert %Ecto.Changeset{} = Events.change_track(track)
    end
  end

  describe "comments" do
    alias Eventos.Events.Comment

    @valid_attrs %{text: "some text"}
    @update_attrs %{text: "some updated text"}
    @invalid_attrs %{text: nil, url: nil}

    def comment_fixture() do
      insert(:comment)
    end

    test "list_comments/0 returns all comments" do
      comment = comment_fixture()
      comments = Events.list_comments()
      assert comments = [comment]
    end

    test "get_comment!/1 returns the comment with given id" do
      comment = comment_fixture()
      comment_fetched = Events.get_comment!(comment.id)
      assert comment_fetched = comment
    end

    test "create_comment/1 with valid data creates a comment" do
      actor = actor_fixture()
      comment_data = Map.merge(@valid_attrs, %{actor_id: actor.id})
      assert {:ok, %Comment{} = comment} = Events.create_comment(comment_data)
      assert comment.text == "some text"
      assert comment.actor_id == actor.id
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_comment(@invalid_attrs)
    end

    test "update_comment/2 with valid data updates the comment" do
      comment = comment_fixture()
      assert {:ok, comment} = Events.update_comment(comment, @update_attrs)
      assert %Comment{} = comment
      assert comment.text == "some updated text"
    end

    test "update_comment/2 with invalid data returns error changeset" do
      comment = comment_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_comment(comment, @invalid_attrs)
      comment_fetched = Events.get_comment!(comment.id)
      assert comment = comment_fetched
    end

    test "delete_comment/1 deletes the comment" do
      comment = comment_fixture()
      assert {:ok, %Comment{}} = Events.delete_comment(comment)
      assert_raise Ecto.NoResultsError, fn -> Events.get_comment!(comment.id) end
    end

    test "change_comment/1 returns a comment changeset" do
      comment = comment_fixture()
      assert %Ecto.Changeset{} = Events.change_comment(comment)
    end
  end
end
