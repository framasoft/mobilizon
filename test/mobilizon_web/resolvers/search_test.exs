defmodule MobilizonWeb.Resolvers.SearchResolverTest do
  use MobilizonWeb.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Service.Workers
  alias MobilizonWeb.AbsintheHelpers

  setup %{conn: conn} do
    user = insert(:user)

    {:ok, conn: conn, user: user}
  end

  test "search_events/3 finds events with basic search", %{
    conn: conn,
    user: user
  } do
    insert(:actor, user: user, preferred_username: "test_person")
    insert(:actor, type: :Group, preferred_username: "test_group")
    event = insert(:event, title: "test_event")
    Workers.BuildSearch.insert_search_event(event)

    query = """
    {
        search_events(search: "test") {
            total,
            elements {
              title,
              uuid,
              __typename
            }
        },
    }
    """

    res =
      conn
      |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

    assert json_response(res, 200)["errors"] == nil
    assert json_response(res, 200)["data"]["search_events"]["total"] == 1
    assert json_response(res, 200)["data"]["search_events"]["elements"] |> length == 1

    assert hd(json_response(res, 200)["data"]["search_events"]["elements"])["uuid"] ==
             to_string(event.uuid)
  end

  test "search_persons/3 finds persons with basic search", %{
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

    assert hd(json_response(res, 200)["data"]["search_persons"]["elements"])["preferredUsername"] ==
             actor.preferred_username
  end

  test "search_groups/3 finds persons with basic search", %{
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

  test "search_events/3 finds events and actors with word search", %{
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

    query = """
    {
        search_events(search: "pineapple") {
          total,
          elements {
            title,
            uuid,
            __typename
          }
        }
    }
    """

    res =
      conn
      |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

    assert json_response(res, 200)["errors"] == nil
    assert json_response(res, 200)["data"]["search_events"]["total"] == 2

    assert json_response(res, 200)["data"]["search_events"]["elements"]
           |> length == 2

    assert json_response(res, 200)["data"]["search_events"]["elements"]
           |> Enum.map(& &1["title"]) == [
             "Pineapple fashion week",
             "I love pineAPPLE"
           ]
  end

  test "search_persons/3 finds persons with word search", %{
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

    assert hd(json_response(res, 200)["data"]["search_persons"]["elements"])["preferredUsername"] ==
             actor.preferred_username
  end

  test "search_events/3 finds events with accented search", %{
    conn: conn,
    user: user
  } do
    insert(:actor, user: user, preferred_username: "person", name: "Torréfaction du Kafé")
    insert(:actor, type: :Group, preferred_username: "group", name: "Kafé group")
    event = insert(:event, title: "Tour du monde des Kafés")
    Workers.BuildSearch.insert_search_event(event)

    # Elaborate query
    query = """
    {
        search_events(search: "Kafé") {
          total,
          elements {
            title,
            uuid,
            __typename
          }
        }
    }
    """

    res =
      conn
      |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

    assert json_response(res, 200)["errors"] == nil
    assert json_response(res, 200)["data"]["search_events"]["total"] == 1
    assert hd(json_response(res, 200)["data"]["search_events"]["elements"])["uuid"] == event.uuid
  end

  test "search_groups/3 finds groups with accented search", %{
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
