defmodule MobilizonWeb.API.SearchTest do
  use ExUnit.Case, async: false

  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub
  alias MobilizonWeb.API.Search

  import Mock

  test "search an user by username" do
    with_mock ActivityPub,
      find_or_make_actor_from_nickname: fn "toto@domain.tld" -> {:ok, %Actor{id: 1}} end do
      assert {:ok, %Actor{id: 1}} == Search.search("toto@domain.tld")
      assert_called(ActivityPub.find_or_make_actor_from_nickname("toto@domain.tld"))
    end
  end

  test "search something by URL" do
    with_mock ActivityPub,
      fetch_object_from_url: fn "https://social.tcit.fr/users/tcit" -> {:ok, %Actor{id: 1}} end do
      assert {:ok, %Actor{id: 1}} == Search.search("https://social.tcit.fr/users/tcit")
      assert_called(ActivityPub.fetch_object_from_url("https://social.tcit.fr/users/tcit"))
    end
  end

  test "search everything" do
    with_mocks([
      {Actors, [], [find_actors_by_username_or_name: fn "toto", 1, 10 -> [%Actor{}] end]},
      {Events, [], [find_events_by_name: fn "toto", 1, 10 -> [%Event{}] end]}
    ]) do
      assert {:ok, [%Event{}, %Actor{}]} = Search.search("toto")
      assert_called(Actors.find_actors_by_username_or_name("toto", 1, 10))
      assert_called(Events.find_events_by_name("toto", 1, 10))
    end
  end

  test "search actors" do
    with_mock Actors,
      find_actors_by_username_or_name: fn "toto", 1, 10 -> [%Actor{}] end do
      assert {:ok, [%Actor{}]} = Search.search_actors("toto")
      assert_called(Actors.find_actors_by_username_or_name("toto", 1, 10))
    end
  end

  test "search events" do
    with_mock Events,
      find_events_by_name: fn "toto", 1, 10 -> [%Event{}] end do
      assert {:ok, [%Event{}]} = Search.search_events("toto")
      assert_called(Events.find_events_by_name("toto", 1, 10))
    end
  end
end
