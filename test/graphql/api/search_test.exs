defmodule Mobilizon.GraphQL.API.SearchTest do
  use ExUnit.Case, async: false

  import Mock

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Page

  alias Mobilizon.GraphQL.API.Search

  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor

  test "search an user by username" do
    with_mock ActivityPubActor,
      find_or_make_actor_from_nickname: fn "toto@domain.tld" -> {:ok, %Actor{id: 42}} end do
      assert {:ok, %Page{total: 1, elements: [%Actor{id: 42}]}} ==
               Search.search_actors(%{term: "toto@domain.tld"}, 1, 10, :Person)

      assert_called(ActivityPubActor.find_or_make_actor_from_nickname("toto@domain.tld"))
    end
  end

  test "search something by URL" do
    with_mock ActivityPub,
      fetch_object_from_url: fn "https://social.tcit.fr/users/tcit" -> {:ok, %Actor{id: 42}} end do
      assert {:ok, %Page{total: 1, elements: [%Actor{id: 42}]}} ==
               Search.search_actors(%{term: "https://social.tcit.fr/users/tcit"}, 1, 10, :Person)

      assert_called(ActivityPub.fetch_object_from_url("https://social.tcit.fr/users/tcit"))
    end
  end

  test "search actors" do
    with_mock Actors,
      build_actors_by_username_or_name_page: fn "toto", _options, 1, 10 ->
        %Page{total: 1, elements: [%Actor{id: 42}]}
      end do
      assert {:ok, %{total: 1, elements: [%Actor{id: 42}]}} =
               Search.search_actors(%{term: "toto"}, 1, 10, :Person)

      assert_called(
        Actors.build_actors_by_username_or_name_page(
          "toto",
          [actor_type: [:Person], radius: nil, location: nil, minimum_visibility: :public],
          1,
          10
        )
      )
    end
  end

  test "search events" do
    with_mock Events,
      build_events_for_search: fn %{term: "toto"}, 1, 10 ->
        %Page{total: 1, elements: [%Event{title: "super toto event"}]}
      end do
      assert {:ok, %{total: 1, elements: [%Event{title: "super toto event"}]}} =
               Search.search_events(%{term: "toto"}, 1, 10)

      assert_called(Events.build_events_for_search(%{term: "toto"}, 1, 10))
    end
  end
end
