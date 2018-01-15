defmodule Eventos.EventsTest do
  use Eventos.DataCase

  import Eventos.Factory

  alias Eventos.Events
  alias Eventos.Accounts

  @account_valid_attrs %{description: "some description", display_name: "some display_name", domain: "some domain", private_key: "some private_key", public_key: "some public_key", suspended: true, uri: "some uri", url: "some url", username: "some username"}
  @event_valid_attrs %{begins_on: "2010-04-17 14:00:00.000000Z", description: "some description", ends_on: "2010-04-17 14:00:00.000000Z", title: "some title"}

  def account_fixture do
    insert(:account)
  end

  def event_fixture do
    insert(:event, organizer: account_fixture())
  end

  def category_fixture do
    insert(:category)
  end

  describe "events" do
    alias Eventos.Events.Event

    @account_valid_attrs %{description: "some description", display_name: "some display_name", domain: "some domain", private_key: "some private_key", public_key: "some public_key", suspended: true, uri: "some uri", url: "some url", username: "some username"}
    @valid_attrs %{begins_on: "2010-04-17 14:00:00.000000Z", description: "some description", ends_on: "2010-04-17 14:00:00.000000Z", title: "some title"}
    @update_attrs %{begins_on: "2011-05-18 15:01:01.000000Z", description: "some updated description", ends_on: "2011-05-18 15:01:01.000000Z", title: "some updated title"}
    @invalid_attrs %{begins_on: nil, description: nil, ends_on: nil, title: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert hd(Events.list_events()).title == event.title
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Events.get_event!(event.id).title == event.title
    end

    test "create_event/1 with valid data creates a event" do
      {:ok, account} = Accounts.create_account(@account_valid_attrs)
      category = category_fixture()
      valid_attrs_with_account_id = Map.put(@event_valid_attrs, :organizer_id, account.id)
      valid_attrs_with_account_id = Map.put(valid_attrs_with_account_id, :category_id, category.id)
      assert {:ok, %Event{} = event} = Events.create_event(valid_attrs_with_account_id)
      assert event.begins_on == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert event.description == "some description"
      assert event.ends_on == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert event.title == "some title"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      assert {:ok, event} = Events.update_event(event, @update_attrs)
      assert %Event{} = event
      assert event.begins_on == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert event.description == "some updated description"
      assert event.ends_on == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert event.title == "some updated title"
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event(event, @invalid_attrs)
      assert event.title == Events.get_event!(event.id).title
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Events.change_event(event)
    end
  end

  describe "event_requests" do
    alias Eventos.Events.Request

    @valid_attrs %{state: 42}
    @update_attrs %{state: 43}
    @invalid_attrs %{state: nil}

    def event_request_fixture(attrs \\ %{}) do
      event = event_fixture()
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)
      {:ok, event_request} =
        attrs
        |> Enum.into(valid_attrs)
        |> Events.create_request()

      event_request
    end

    test "list_event_requests/0 returns all event_requests" do
      event_request = event_request_fixture()
      assert Events.list_requests() == [event_request]
    end

    test "get_request!/1 returns the event_request with given id" do
      event_request = event_request_fixture()
      assert Events.get_request!(event_request.id) == event_request
    end

    test "create_request/1 with valid data creates a event_request" do
      assert {:ok, %Request{} = event_request} = Events.create_request(@valid_attrs)
      assert event_request.state == 42
    end

    test "create_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_request(@invalid_attrs)
    end

    test "update_event_request/2 with valid data updates the event_request" do
      event_request = event_request_fixture()
      assert {:ok, event_request} = Events.update_request(event_request, @update_attrs)
      assert %Request{} = event_request
      assert event_request.state == 43
    end

    test "update_event_request/2 with invalid data returns error changeset" do
      event_request = event_request_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_request(event_request, @invalid_attrs)
      assert event_request == Events.get_request!(event_request.id)
    end

    test "delete_event_request/1 deletes the event_request" do
      event_request = event_request_fixture()
      assert {:ok, %Request{}} = Events.delete_request(event_request)
      assert_raise Ecto.NoResultsError, fn -> Events.get_request!(event_request.id) end
    end

    test "change_event_request/1 returns a event_request changeset" do
      event_request = event_request_fixture()
      assert %Ecto.Changeset{} = Events.change_request(event_request)
    end
  end

  describe "categories" do
    alias Eventos.Events.Category

    @valid_attrs %{description: "some description", picture: "some picture", title: "some title"}
    @update_attrs %{description: "some updated description", picture: "some updated picture", title: "some updated title"}
    @invalid_attrs %{description: nil, picture: nil, title: nil}

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Events.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Events.get_category!(category.id) == category
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

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      assert {:ok, category} = Events.update_category(category, @update_attrs)
      assert %Category{} = category
      assert category.description == "some updated description"
      assert category.picture == "some updated picture"
      assert category.title == "some updated title"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_category(category, @invalid_attrs)
      assert category == Events.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Events.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Events.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
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
    alias Eventos.Events.Participant

    @valid_attrs %{role: 42}
    @update_attrs %{role: 43}
    @invalid_attrs %{role: nil}

    def participant_fixture(attrs \\ %{}) do
      event = event_fixture()
      account = account_fixture()
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)
      valid_attrs = Map.put(valid_attrs, :account_id, account.id)
      {:ok, participant} =
        attrs
        |> Enum.into(valid_attrs)
        |> Events.create_participant()

      participant
    end

    test "list_participants/0 returns all participants" do
      participant = participant_fixture()
      assert Events.list_participants() == [participant]
    end

#    test "get_participant!/1 returns the participant with given id" do
#      participant = participant_fixture()
#      assert Events.get_participant!(participant.id) == participant
#    end

    test "create_participant/1 with valid data creates a participant" do
      account = account_fixture()
      event = event_fixture()
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)
      valid_attrs = Map.put(valid_attrs, :account_id, account.id)
      assert {:ok, %Participant{} = participant} = Events.create_participant(valid_attrs)
      assert participant.role == 42
    end

    test "create_participant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_participant(@invalid_attrs)
    end

    test "update_participant/2 with valid data updates the participant" do
      participant = participant_fixture()
      assert {:ok, participant} = Events.update_participant(participant, @update_attrs)
      assert %Participant{} = participant
      assert participant.role == 43
    end

    test "update_participant/2 with invalid data returns error changeset" do
      participant = participant_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_participant(participant, @invalid_attrs)
    end

    test "delete_participant/1 deletes the participant" do
      participant = participant_fixture()
      assert {:ok, %Participant{}} = Events.delete_participant(participant)
    end

    test "change_participant/1 returns a participant changeset" do
      participant = participant_fixture()
      assert %Ecto.Changeset{} = Events.change_participant(participant)
    end
  end

  describe "requests" do
    alias Eventos.Events.Request

    @valid_attrs %{state: 42}
    @update_attrs %{state: 43}
    @invalid_attrs %{state: nil}

    def request_fixture(attrs \\ %{}) do
      event = event_fixture()
      valid_attrs = Map.put(@valid_attrs, :event_id, event.id)
      {:ok, request} =
        attrs
        |> Enum.into(valid_attrs)
        |> Events.create_request()

      request
    end

    test "list_requests/0 returns all requests" do
      request = request_fixture()
      assert Events.list_requests() == [request]
    end

    test "get_request!/1 returns the request with given id" do
      request = request_fixture()
      assert Events.get_request!(request.id) == request
    end

    test "create_request/1 with valid data creates a request" do
      assert {:ok, %Request{} = request} = Events.create_request(@valid_attrs)
      assert request.state == 42
    end

    test "create_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_request(@invalid_attrs)
    end

    test "update_request/2 with valid data updates the request" do
      request = request_fixture()
      assert {:ok, request} = Events.update_request(request, @update_attrs)
      assert %Request{} = request
      assert request.state == 43
    end

    test "update_request/2 with invalid data returns error changeset" do
      request = request_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_request(request, @invalid_attrs)
      assert request == Events.get_request!(request.id)
    end

    test "delete_request/1 deletes the request" do
      request = request_fixture()
      assert {:ok, %Request{}} = Events.delete_request(request)
      assert_raise Ecto.NoResultsError, fn -> Events.get_request!(request.id) end
    end

    test "change_request/1 returns a request changeset" do
      request = request_fixture()
      assert %Ecto.Changeset{} = Events.change_request(request)
    end
  end

  describe "sessions" do
    alias Eventos.Events.Session

    @valid_attrs %{audios_urls: "some audios_urls", language: "some language", long_abstract: "some long_abstract", short_abstract: "some short_abstract", slides_url: "some slides_url", subtitle: "some subtitle", title: "some title", videos_urls: "some videos_urls"}
    @update_attrs %{audios_urls: "some updated audios_urls", language: "some updated language", long_abstract: "some updated long_abstract", short_abstract: "some updated short_abstract", slides_url: "some updated slides_url", subtitle: "some updated subtitle", title: "some updated title", videos_urls: "some updated videos_urls"}
    @invalid_attrs %{audios_urls: nil, language: nil, long_abstract: nil, short_abstract: nil, slides_url: nil, subtitle: nil, title: nil, videos_urls: nil}

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
    @update_attrs %{color: "some updated color", description: "some updated description", name: "some updated name"}
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
end
