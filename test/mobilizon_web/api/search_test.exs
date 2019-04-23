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
      find_or_make_actor_from_nickname: fn "toto@domain.tld" -> {:ok, %Actor{id: 42}} end do
      assert {:ok, %{total: 1, elements: [%Actor{id: 42}]}} ==
               Search.search_actors("toto@domain.tld", 1, 10, :Person)

      assert_called(ActivityPub.find_or_make_actor_from_nickname("toto@domain.tld"))
    end
  end

  test "search something by URL" do
    with_mock ActivityPub,
      fetch_object_from_url: fn "https://social.tcit.fr/users/tcit" -> {:ok, %Actor{id: 42}} end do
      assert {:ok, %{total: 1, elements: [%Actor{id: 42}]}} ==
               Search.search_actors("https://social.tcit.fr/users/tcit", 1, 10, :Person)

      assert_called(ActivityPub.fetch_object_from_url("https://social.tcit.fr/users/tcit"))
    end
  end

  test "search actors" do
    with_mock Actors,
      find_and_count_actors_by_username_or_name: fn "toto", _type, 1, 10 ->
        %{total: 1, elements: [%Actor{id: 42}]}
      end do
      assert {:ok, %{total: 1, elements: [%Actor{id: 42}]}} =
               Search.search_actors("toto", 1, 10, :Person)

      assert_called(Actors.find_and_count_actors_by_username_or_name("toto", [:Person], 1, 10))
    end
  end

  test "search events" do
    with_mock Events,
      find_and_count_events_by_name: fn "toto", 1, 10 ->
        %{total: 1, elements: [%Event{title: "super toto event"}]}
      end do
      assert {:ok, %{total: 1, elements: [%Event{title: "super toto event"}]}} =
               Search.search_events("toto", 1, 10)

      assert_called(Events.find_and_count_events_by_name("toto", 1, 10))
    end
  end
end
