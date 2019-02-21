defmodule MobilizonWeb.Resolvers.SearchResolverTest do
  use MobilizonWeb.ConnCase
  alias MobilizonWeb.AbsintheHelpers
  import Mobilizon.Factory

  setup %{conn: conn} do
    user = insert(:user)

    {:ok, conn: conn, user: user}
  end

  test "search_events_and_actors/3 finds events and actors with basic search", %{
    conn: conn,
    user: user
  } do
    actor = insert(:actor, user: user, preferred_username: "test")
    event = insert(:event, title: "test")

    query = """
    {
        search(search: "test") {
            ...on Event {
              title,
              uuid,
              __typename
            },
            ...on Actor {
              preferredUsername,
              __typename
            }
          }
    }
    """

    res =
      conn
      |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

    assert hd(json_response(res, 200)["data"]["search"])["uuid"] == to_string(event.uuid)

    assert hd(tl(json_response(res, 200)["data"]["search"]))["preferredUsername"] ==
             actor.preferred_username
  end

  test "search_events_and_actors/3 finds events and actors with word search", %{
    conn: conn,
    user: user
  } do
    actor = insert(:actor, user: user, preferred_username: "toto", name: "I like pineapples")
    event = insert(:event, title: "Pineapple fashion week")

    # Elaborate query
    query = """
    {
        search(search: "pineapple") {
            ...on Event {
              title,
              uuid,
              __typename
            },
            ...on Actor {
              preferredUsername,
              __typename
            }
          }
    }
    """

    res =
      conn
      |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

    assert hd(json_response(res, 200)["data"]["search"])["uuid"] == to_string(event.uuid)

    assert hd(tl(json_response(res, 200)["data"]["search"]))["preferredUsername"] ==
             actor.preferred_username
  end

  test "search_events_and_actors/3 finds events and actors with accented search", %{
    conn: conn,
    user: user
  } do
    insert(:actor, user: user, preferred_username: "toto", name: "Torréfaction")
    event = insert(:event, title: "Tour du monde des cafés")

    # Elaborate query
    query = """
    {
        search(search: "café") {
            ...on Event {
              title,
              uuid,
              __typename
            },
            ...on Actor {
              preferredUsername,
              __typename
            }
          }
    }
    """

    res =
      conn
      |> get("/api", AbsintheHelpers.query_skeleton(query, "search"))

    assert hd(json_response(res, 200)["data"]["search"])["uuid"] == to_string(event.uuid)
  end
end
