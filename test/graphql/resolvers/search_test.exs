defmodule Mobilizon.GraphQL.Resolvers.SearchTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Service.Workers

  alias Mobilizon.GraphQL.AbsintheHelpers

  setup %{conn: conn} do
    user = insert(:user)

    {:ok, conn: conn, user: user}
  end

  describe "search events/3" do
    @search_events_query """
    query SearchEvents($location: String, $radius: Float, $tags: String, $term: String) {
      searchEvents(location: $location, radius: $radius, tags: $tags, term: $term) {
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
  end

  describe "search_persons/3" do
    test "finds persons with basic search", %{
      conn: conn,
      user: user
    } do
      actor = insert(:actor, user: user, preferred_username: "test_person")
      insert(:actor, type: :Group, preferred_username: "test_group")
      event = insert(:event, title: "test_event")
      Workers.BuildSearch.insert_search_event(event)

      query = """
      {
          search_persons(search: "test") {
            total,
            elements {
              preferredUsername,
              __typename
            }
          },
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["search_persons"]["total"] == 1
      assert json_response(res, 200)["data"]["search_persons"]["elements"] |> length == 1

      assert hd(json_response(res, 200)["data"]["search_persons"]["elements"])[
               "preferredUsername"
             ] ==
               actor.preferred_username
    end

    test "finds persons with word search", %{
      conn: conn,
      user: user
    } do
      actor = insert(:actor, user: user, preferred_username: "person", name: "I like pineapples")
      insert(:actor, preferred_username: "group", type: :Group, name: "pineapple group")
      event1 = insert(:event, title: "Pineapple fashion week")
      event2 = insert(:event, title: "I love pineAPPLE")
      event3 = insert(:event, title: "Hello")
      Workers.BuildSearch.insert_search_event(event1)
      Workers.BuildSearch.insert_search_event(event2)
      Workers.BuildSearch.insert_search_event(event3)

      query = """
      {
          search_persons(search: "pineapple") {
            total,
            elements {
              preferredUsername,
              __typename
            }
          }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["search_persons"]["total"] == 1

      assert json_response(res, 200)["data"]["search_persons"]["elements"]
             |> length == 1

      assert hd(json_response(res, 200)["data"]["search_persons"]["elements"])[
               "preferredUsername"
             ] ==
               actor.preferred_username
    end
  end

  describe "search_groups/3" do
    test "finds persons with basic search", %{
      conn: conn,
      user: user
    } do
      insert(:actor, user: user, preferred_username: "test_person")
      group = insert(:actor, type: :Group, preferred_username: "test_group")
      event = insert(:event, title: "test_event")
      Workers.BuildSearch.insert_search_event(event)

      query = """
      {
          search_groups(search: "test") {
            total,
            elements {
              preferredUsername,
              __typename
            }
          },
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["search_groups"]["total"] == 1
      assert json_response(res, 200)["data"]["search_groups"]["elements"] |> length == 1

      assert hd(json_response(res, 200)["data"]["search_groups"]["elements"])["preferredUsername"] ==
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

      # Elaborate query
      query = """
      {
          search_groups(search: "Kafé") {
            total,
            elements {
              preferredUsername,
              __typename
            }
          }
      }
      """

      res =
        conn
        |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

      assert json_response(res, 200)["errors"] == nil
      assert json_response(res, 200)["data"]["search_groups"]["total"] == 1

      assert hd(json_response(res, 200)["data"]["search_groups"]["elements"])["preferredUsername"] ==
               group.preferred_username
    end
  end
end
