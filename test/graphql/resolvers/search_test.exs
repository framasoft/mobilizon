defmodule Mobilizon.GraphQL.Resolvers.SearchTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.GraphQL.AbsintheHelpers
  alias Mobilizon.Service.Workers

  setup %{conn: conn} do
    user = insert(:user)

    {:ok, conn: conn, user: user}
  end

  describe "search events/3" do
    @search_events_query """
    query SearchEvents($location: String, $radius: Float, $tags: String, $term: String, $beginsOn: DateTime, $endsOn: DateTime, $longEvents:Boolean, $searchTarget: SearchTarget) {
      searchEvents(location: $location, radius: $radius, tags: $tags, term: $term, beginsOn: $beginsOn, endsOn: $endsOn, longEvents: $longEvents, searchTarget: $searchTarget) {
        total,
        elements {
          id
          title,
          uuid,
          __typename
        }
      }
    }
    """

    test "finds events with basic search", %{
      conn: conn,
      user: user
    } do
      insert(:actor, user: user, preferred_username: "test_person")
      insert(:actor, type: :Group, preferred_username: "test_group")
      event = insert(:event, title: "test_event")
      Workers.BuildSearch.insert_search_event(event)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{term: "test"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 1
      assert res["data"]["searchEvents"]["elements"] |> length == 1

      assert hd(res["data"]["searchEvents"]["elements"])["uuid"] ==
               to_string(event.uuid)
    end

    test "finds events and actors with word search", %{
      conn: conn,
      user: user
    } do
      insert(:actor, user: user, preferred_username: "person", name: "I like pineapples")
      event1 = insert(:event, title: "Pineapple fashion week")
      event2 = insert(:event, title: "I love pineAPPLE")
      event3 = insert(:event, title: "Hello")
      Workers.BuildSearch.insert_search_event(event1)
      Workers.BuildSearch.insert_search_event(event2)
      Workers.BuildSearch.insert_search_event(event3)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{term: "pineapple"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 2

      assert res["data"]["searchEvents"]["elements"]
             |> length == 2

      assert res["data"]["searchEvents"]["elements"]
             |> Enum.map(& &1["title"]) == [
               "Pineapple fashion week",
               "I love pineAPPLE"
             ]
    end

    test "finds events with accented search", %{
      conn: conn,
      user: user
    } do
      insert(:actor, user: user, preferred_username: "person", name: "Torréfaction du Kafé")
      insert(:actor, type: :Group, preferred_username: "group", name: "Kafé group")
      event = insert(:event, title: "Tour du monde des Kafés")
      Workers.BuildSearch.insert_search_event(event)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{term: "Kafés"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 1

      assert hd(res["data"]["searchEvents"]["elements"])["uuid"] ==
               event.uuid
    end

    test "finds events by tag", %{conn: conn} do
      tag = insert(:tag, title: "Café")
      tag2 = insert(:tag, title: "Thé")
      event = insert(:event, title: "Tour du monde", tags: [tag, tag2])
      insert(:event, title: "Autre événement")
      Workers.BuildSearch.insert_search_event(event)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{tags: "Café,Sirop"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 1

      assert hd(res["data"]["searchEvents"]["elements"])["uuid"] ==
               event.uuid
    end

    test "finds events by location", %{conn: conn} do
      {lon, lat} = {45.75, 4.85}
      point = %Geo.Point{coordinates: {lon, lat}, srid: 4326}
      geohash = Geohax.encode(lon, lat, 6)
      address = insert(:address, geom: point)
      event = insert(:event, title: "Tour du monde", physical_address: address)
      Workers.BuildSearch.insert_search_event(event)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{location: geohash}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 1

      assert hd(res["data"]["searchEvents"]["elements"])["uuid"] ==
               event.uuid
    end

    test "finds events by begins_on and ends_on", %{conn: conn} do
      Config.put([:instance, :duration_of_long_event], 0)
      now = DateTime.utc_now()

      # TODO
      event =
        insert(:event,
          title: "Tour du monde",
          begins_on: DateTime.add(now, 3600 * 24 * 3),
          ends_on: DateTime.add(now, 3600 * 24 * 10)
        )

      insert(:event,
        title: "Autre événement",
        begins_on: DateTime.add(now, 3600 * 24 * 30),
        ends_on: nil
      )

      Workers.BuildSearch.insert_search_event(event)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{
            beginsOn: now |> DateTime.add(86_400) |> DateTime.to_iso8601(),
            endsOn: now |> DateTime.add(1_728_000) |> DateTime.to_iso8601()
          }
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 1

      assert hd(res["data"]["searchEvents"]["elements"])["uuid"] ==
               event.uuid
    end

    test "finds 4 events : long event disabled", %{conn: conn} do
      Config.put([:instance, :duration_of_long_event], 0)
      now = DateTime.utc_now()

      event1 =
        insert(:event,
          title: "Cours 10j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 14)
        )

      event2 =
        insert(:event,
          title: "Long 29j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 33)
        )

      event3 =
        insert(:event,
          title: "Long 31j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 35)
        )

      event4 =
        insert(:event,
          title: "Long 40j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 44)
        )

      Workers.BuildSearch.insert_search_event(event1)
      Workers.BuildSearch.insert_search_event(event2)
      Workers.BuildSearch.insert_search_event(event3)
      Workers.BuildSearch.insert_search_event(event4)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{longEvents: false}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 4

      assert res["data"]["searchEvents"]["elements"]
             |> Enum.map(& &1["uuid"]) == [
               event1.uuid,
               event2.uuid,
               event3.uuid,
               event4.uuid
             ]

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{longEvents: true}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 4

      assert res["data"]["searchEvents"]["elements"]
             |> Enum.map(& &1["uuid"]) == [
               event1.uuid,
               event2.uuid,
               event3.uuid,
               event4.uuid
             ]
    end

    test "finds 4 events : long event enabled 30 days", %{conn: conn} do
      Config.put([:instance, :duration_of_long_event], 30)
      now = DateTime.utc_now()

      event1 =
        insert(:event,
          title: "Cours 10j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 15)
        )

      event2 =
        insert(:event,
          title: "Long 30j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 35)
        )

      event3 =
        insert(:event,
          title: "Long 31j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 36)
        )

      event4 =
        insert(:event,
          title: "Long 40j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 45)
        )

      Workers.BuildSearch.insert_search_event(event1)
      Workers.BuildSearch.insert_search_event(event2)
      Workers.BuildSearch.insert_search_event(event3)
      Workers.BuildSearch.insert_search_event(event4)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{longEvents: false}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 2

      assert res["data"]["searchEvents"]["elements"]
             |> Enum.map(& &1["uuid"]) == [
               event1.uuid,
               event2.uuid
             ]

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{longEvents: true}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 2

      assert res["data"]["searchEvents"]["elements"]
             |> Enum.map(& &1["uuid"]) == [
               event3.uuid,
               event4.uuid
             ]
    end

    test "finds 4 events : long event enabled 15 days", %{conn: conn} do
      Config.put([:instance, :duration_of_long_event], 15)
      now = DateTime.utc_now()

      event1 =
        insert(:event,
          title: "Cours 10j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 15)
        )

      event2 =
        insert(:event,
          title: "Long 30j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 35)
        )

      event3 =
        insert(:event,
          title: "Long 31j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 36)
        )

      event4 =
        insert(:event,
          title: "Long 40j",
          begins_on: DateTime.add(now, 3600 * 24 * 5),
          ends_on: DateTime.add(now, 3600 * 24 * 45)
        )

      Workers.BuildSearch.insert_search_event(event1)
      Workers.BuildSearch.insert_search_event(event2)
      Workers.BuildSearch.insert_search_event(event3)
      Workers.BuildSearch.insert_search_event(event4)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{longEvents: false}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 1

      assert res["data"]["searchEvents"]["elements"]
             |> Enum.map(& &1["uuid"]) == [
               event1.uuid
             ]

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{longEvents: true}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 3

      assert res["data"]["searchEvents"]["elements"]
             |> Enum.map(& &1["uuid"]) == [
               event2.uuid,
               event3.uuid,
               event4.uuid
             ]
    end

    test "finds events with multiple criteria", %{conn: conn} do
      {lon, lat} = {45.75, 4.85}
      point = %Geo.Point{coordinates: {lon, lat}, srid: 4326}
      geohash = Geohax.encode(lon, lat, 6)
      address = insert(:address, geom: point)
      tag = insert(:tag, title: "Café")
      tag2 = insert(:tag, title: "Thé")
      event = insert(:event, title: "Tour du monde", physical_address: address, tags: [tag, tag2])
      insert(:event, title: "Autre événement avec même tags", tags: [tag, tag2])
      insert(:event, title: "Même endroit", physical_address: address)
      insert(:event, title: "Même monde")
      Workers.BuildSearch.insert_search_event(event)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{location: geohash, radius: 10, tags: "Thé", term: "Monde"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 1

      assert hd(res["data"]["searchEvents"]["elements"])["uuid"] ==
               event.uuid
    end

    test "doesn't find drafts", %{conn: conn} do
      insert(:event, title: "A draft event", draft: true)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{term: "draft"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 0
    end

    test "finds events for the correct target", %{conn: conn} do
      event1 = insert(:event, title: "A local event")

      %Actor{id: remote_instance_actor_id} = remote_instance_actor = insert(:instance_actor)
      %Actor{id: remote_actor_id} = insert(:actor, domain: "somedomain.tld", user: nil)

      %Event{url: remote_event_url} =
        event2 = insert(:event, local: false, title: "My Remote event")

      Mobilizon.Share.create(remote_event_url, remote_instance_actor_id, remote_actor_id)

      %Actor{} = own_instance_actor = Relay.get_actor()

      insert(:follower, target_actor: remote_instance_actor, actor: own_instance_actor)
      Workers.BuildSearch.insert_search_event(event1)
      Workers.BuildSearch.insert_search_event(event2)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{term: "event"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 2
      elements = res["data"]["searchEvents"]["elements"]

      assert MapSet.new(Enum.map(elements, & &1["id"])) ==
               MapSet.new([to_string(event1.id), to_string(event2.id)])

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_events_query,
          variables: %{term: "event", searchTarget: "SELF"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchEvents"]["total"] == 1
    end
  end

  describe "search_persons/3" do
    @search_persons_query """
    query SearchPersons($term: String!, $page: Int, $limit: Int) {
      searchPersons(term: $term, page: $page, limit: $limit) {
        total
        elements {
          id
          avatar {
            url
          }
          domain
          preferredUsername
          name
          __typename
        }
      }
    }
    """

    test "without being logged-in", %{
      conn: conn
    } do
      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_persons_query,
          variables: %{term: "test"}
        )

      assert hd(res["errors"])["message"] == "You need to be logged in"
    end

    test "without being a moderator", %{
      conn: conn,
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @search_persons_query, variables: %{term: "test"})

      assert hd(res["errors"])["message"] == "You don't have permission to do this"
    end

    test "finds persons with basic search", %{
      conn: conn
    } do
      user = insert(:user, role: :moderator)
      actor = insert(:actor, preferred_username: "test_person")
      insert(:actor, type: :Group, preferred_username: "test_group")
      event = insert(:event, title: "test_event")
      Workers.BuildSearch.insert_search_event(event)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(query: @search_persons_query, variables: %{term: "test"})

      assert res["errors"] == nil
      assert res["data"]["searchPersons"]["total"] == 1
      assert res["data"]["searchPersons"]["elements"] |> length == 1

      assert hd(res["data"]["searchPersons"]["elements"])["preferredUsername"] ==
               actor.preferred_username
    end

    test "finds persons with word search", %{
      conn: conn
    } do
      user = insert(:user, role: :moderator)
      actor = insert(:actor, preferred_username: "person", name: "I like pineapples")
      insert(:actor, preferred_username: "group", type: :Group, name: "pineapple group")
      event1 = insert(:event, title: "Pineapple fashion week")
      event2 = insert(:event, title: "I love pineAPPLE")
      event3 = insert(:event, title: "Hello")
      Workers.BuildSearch.insert_search_event(event1)
      Workers.BuildSearch.insert_search_event(event2)
      Workers.BuildSearch.insert_search_event(event3)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @search_persons_query,
          variables: %{term: "pineapple"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchPersons"]["total"] == 1

      assert res["data"]["searchPersons"]["elements"]
             |> length == 1

      assert hd(res["data"]["searchPersons"]["elements"])["preferredUsername"] ==
               actor.preferred_username
    end
  end

  describe "search_groups/3" do
    @search_groups_query """
    query SearchGroups($term: String, $location: String, $radius: Float) {
    searchGroups(term: $term, location: $location, radius: $radius) {
      total
      elements {
        avatar {
          url
        }
        domain
        preferredUsername
        name
        __typename
      }
    }
    }
    """

    test "finds persons with basic search", %{
      conn: conn,
      user: user
    } do
      insert(:actor, user: user, preferred_username: "test_person")
      group = insert(:actor, type: :Group, preferred_username: "test_group")
      event = insert(:event, title: "test_event")
      Workers.BuildSearch.insert_search_event(event)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_groups_query,
          variables: %{term: "test"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchGroups"]["total"] == 1
      assert res["data"]["searchGroups"]["elements"] |> length == 1

      assert hd(res["data"]["searchGroups"]["elements"])["preferredUsername"] ==
               group.preferred_username
    end

    test "finds groups with accented search", %{
      conn: conn,
      user: user
    } do
      insert(:actor, user: user, preferred_username: "person", name: "Torréfaction du Kafé")
      group = insert(:actor, type: :Group, preferred_username: "group", name: "Kafé group")
      event = insert(:event, title: "Tour du monde des Kafés")
      Workers.BuildSearch.insert_search_event(event)

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_groups_query,
          variables: %{term: "Kafé"}
        )

      assert res["errors"] == nil
      assert res["data"]["searchGroups"]["total"] == 1

      assert hd(res["data"]["searchGroups"]["elements"])["preferredUsername"] ==
               group.preferred_username
    end

    test "finds groups with location", %{conn: conn} do
      {lon, lat} = {45.75, 4.85}
      point = %Geo.Point{coordinates: {lon, lat}, srid: 4326}
      geohash = Geohax.encode(lon, lat, 6)
      geohash_2 = Geohax.encode(25, -19, 6)
      address = insert(:address, geom: point)

      group =
        insert(:actor,
          type: :Group,
          preferred_username: "want_coffee",
          name: "Want coffee ?",
          physical_address: address
        )

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_groups_query,
          variables: %{location: geohash}
        )

      assert res["errors"] == nil
      assert res["data"]["searchGroups"]["total"] == 1

      assert hd(res["data"]["searchGroups"]["elements"])["preferredUsername"] ==
               group.preferred_username

      res =
        AbsintheHelpers.graphql_query(conn,
          query: @search_groups_query,
          variables: %{location: geohash_2}
        )

      assert res["errors"] == nil
      assert res["data"]["searchGroups"]["total"] == 0
    end
  end
end
